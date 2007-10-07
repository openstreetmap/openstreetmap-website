#include <mysql.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vector>
#include <list>
#include <sstream>
#include <map>
#include <string>

#ifdef __amd64__

#define F_U64 "%lu"
#define F_U32 "%u"

#else

#define F_U64 "%Lu"
#define F_U32 "%u"

#endif

using namespace std;

template <typename T>
static T parse(const char *str) {
  istringstream in(str);
  T t;
  in >> t;
  return t;
}

static void exit_mysql_err(MYSQL *mysql) {
  const char *err = mysql_error(mysql);
  if (err) {
    fprintf(stderr, "008_remove_segments_helper: MySQL error: %s\n", err);
  } else {
    fprintf(stderr, "008_remove_segments_helper: MySQL error\n");
  }
  abort();
  exit(EXIT_FAILURE);
}

static void exit_stmt_err(MYSQL_STMT *stmt) {
  const char *err = mysql_stmt_error(stmt);
  if (err) {
    fprintf(stderr, "008_remove_segments_helper: MySQL stmt error: %s\n", err);
  } else {
    fprintf(stderr, "008_remove_segments_helper: MySQL stmt error\n");
  }
  abort();
  exit(EXIT_FAILURE);
}

struct segment {
  uint32_t from, to;
};

struct data {
  MYSQL *mysql, *mysql2;

  uint64_t seg_maxid, way_maxid;
  uint64_t new_way_id;
  uint64_t new_relation_id;

  size_t segs_len;
  struct segment *segs;
  unsigned char *rem_segs;
  unsigned char *tgd_segs;

  FILE *ways, *way_nodes, *way_tags,
    *relations, *relation_members, *relation_tags;
};

static uint64_t select_u64(MYSQL *mysql, const char *q) {
  MYSQL_RES *res;
  MYSQL_ROW row;
  uint64_t ret;

  if (mysql_query(mysql, q))
    exit_mysql_err(mysql);

  res = mysql_store_result(mysql);
  if (!res) exit_mysql_err(mysql);

  row = mysql_fetch_row(res);
  if (!row) exit_mysql_err(mysql);

  if (row[0]) {
    ret = parse<uint64_t>(row[0]);
  } else {
    ret = 0;
  }

  mysql_free_result(res);

  return ret;
}

static void find_maxids(struct data *d) {
  d->seg_maxid = select_u64(d->mysql, "SELECT max(id) FROM current_segments");
  d->segs_len = d->seg_maxid + 1;
  d->way_maxid = select_u64(d->mysql, "SELECT max(id) FROM current_ways");
  d->new_way_id = d->way_maxid + 1;
  d->new_relation_id = select_u64(d->mysql, "SELECT max(id) FROM current_relations") + 1;
}

static void populate_segs(struct data *d) {
  MYSQL_RES *res;
  MYSQL_ROW row;
  size_t id;

  d->segs = (segment *) malloc(sizeof(struct segment) * d->segs_len);
  memset(d->segs, 0, sizeof(struct segment) * d->segs_len);

  d->rem_segs = (unsigned char *) malloc(d->segs_len);
  d->tgd_segs = (unsigned char *) malloc(d->segs_len);
  memset(d->rem_segs, 0, d->segs_len);
  memset(d->tgd_segs, 0, d->segs_len);

  if (mysql_query(d->mysql, "SELECT id, node_a, node_b "
      "FROM current_segments WHERE visible"))
    exit_mysql_err(d->mysql);

  res = mysql_use_result(d->mysql);
  if (!res) exit_mysql_err(d->mysql);

  while ((row = mysql_fetch_row(res))) {
    id = parse<size_t>(row[0]);
    if (id >= d->segs_len) continue;
    d->segs[id].from = parse<uint32_t>(row[1]);
    d->segs[id].to   = parse<uint32_t>(row[2]);
    d->rem_segs[id] = 1;
  }
  if (mysql_errno(d->mysql)) exit_mysql_err(d->mysql);

  mysql_free_result(res);
}

static void write_csv_col(FILE *f, const char *str, char end) {
  char *out = (char *) malloc(2 * strlen(str) + 4);
  char *o = out;
  size_t len;

  *(o++) = '\"';
  for (; *str; str++) {
    if (*str == '\0') {
      break;
    } else if (*str == '\"') {
      *(o++) = '\"';
      *(o++) = '\"';
    } else {
      *(o++) = *str;
    }
  }
  *(o++) = '\"';
  *(o++) = end;
  *(o++) = '\0';

  len = strlen(out);
  if (fwrite(out, len, 1, f) != 1) {
    perror("fwrite");
    exit(EXIT_FAILURE);
  }

  free(out);
}

static void convert_ways(struct data *d) {
  MYSQL_RES *res;
  MYSQL_ROW row;
  MYSQL_STMT *load_segs, *load_tags;
  const char
    load_segs_stmt[] = "SELECT segment_id FROM current_way_segments "
      "WHERE id = ? ORDER BY sequence_id",
    load_tags_stmt[] = "SELECT k, v FROM current_way_tags WHERE id = ?";
  char *k, *v;
  const size_t max_tag_len = 1 << 16;
  long long mysql_id, mysql_seg_id;
  unsigned long res_len;
  my_bool res_error;
  MYSQL_BIND bind[1], seg_bind[1], tag_bind[2];

  /* F***ing libmysql only support fixed size buffers for string results of
   * prepared statements.  So allocate 65k for the tag key and the tag value
   * and hope it'll suffice. */
  k = (char *) malloc(max_tag_len);
  v = (char *) malloc(max_tag_len);

  load_segs = mysql_stmt_init(d->mysql2);
  if (!load_segs) exit_mysql_err(d->mysql2);
  if (mysql_stmt_prepare(load_segs, load_segs_stmt, sizeof(load_segs_stmt)))
    exit_stmt_err(load_segs);

  memset(bind, 0, sizeof(bind));
  bind[0].buffer_type = MYSQL_TYPE_LONGLONG;
  bind[0].buffer = (char *) &mysql_id;
  bind[0].is_null = 0;
  bind[0].length = 0;
  if (mysql_stmt_bind_param(load_segs, bind))
    exit_stmt_err(load_segs);

  memset(seg_bind, 0, sizeof(seg_bind));
  seg_bind[0].buffer_type = MYSQL_TYPE_LONGLONG;
  seg_bind[0].buffer = (char *) &mysql_seg_id;
  seg_bind[0].is_null = 0;
  seg_bind[0].length = 0;
  seg_bind[0].error = &res_error;
  if (mysql_stmt_bind_result(load_segs, seg_bind))
    exit_stmt_err(load_segs);

  load_tags = mysql_stmt_init(d->mysql2);
  if (!load_tags) exit_mysql_err(d->mysql2);
  if (mysql_stmt_prepare(load_tags, load_tags_stmt, sizeof(load_tags_stmt)))
    exit_stmt_err(load_tags);

  memset(bind, 0, sizeof(bind));
  bind[0].buffer_type = MYSQL_TYPE_LONGLONG;
  bind[0].buffer = (char *) &mysql_id;
  bind[0].is_null = 0;
  bind[0].length = 0;

  if (mysql_stmt_bind_param(load_tags, bind))
    exit_stmt_err(load_tags);

  memset(tag_bind, 0, sizeof(tag_bind));
  tag_bind[0].buffer_type = MYSQL_TYPE_STRING;
  tag_bind[0].buffer = k;
  tag_bind[0].is_null = 0;
  tag_bind[0].length = &res_len;
  tag_bind[0].error = &res_error;
  tag_bind[0].buffer_length = max_tag_len;
  tag_bind[1].buffer_type = MYSQL_TYPE_STRING;
  tag_bind[1].buffer = v;
  tag_bind[1].is_null = 0;
  tag_bind[1].length = &res_len;
  tag_bind[1].error = &res_error;
  tag_bind[1].buffer_length = max_tag_len;
  if (mysql_stmt_bind_result(load_tags, tag_bind))
    exit_stmt_err(load_tags);

  if (mysql_query(d->mysql, "SELECT id, user_id, timestamp "
      "FROM current_ways WHERE visible"))
    exit_mysql_err(d->mysql);

  res = mysql_use_result(d->mysql);
  if (!res) exit_mysql_err(d->mysql);

  while ((row = mysql_fetch_row(res))) {
    uint64_t id;
    const char *user_id, *timestamp;

    id = parse<uint64_t>(row[0]);
    user_id = row[1];
    timestamp = row[2];

    mysql_id = (long long) id;

    if (mysql_stmt_execute(load_segs))
      exit_stmt_err(load_segs);

    if (mysql_stmt_store_result(load_segs))
      exit_stmt_err(load_segs);

    list<segment> segs;
    while (!mysql_stmt_fetch(load_segs)) {
      if (((uint64_t) mysql_seg_id) >= d->segs_len) continue;
      segs.push_back(d->segs[mysql_seg_id]);
      d->rem_segs[mysql_seg_id] = 0;
    }

    list<list<uint32_t> > node_lists;
    while (segs.size()) {
      list<uint32_t> node_list;
      node_list.push_back(segs.front().from);
      node_list.push_back(segs.front().to);
      segs.pop_front();
      while (true) {
        bool found = false;
        for (list<segment>::iterator it = segs.begin();
            it != segs.end(); ) {
          if (it->from == node_list.back()) {
            node_list.push_back(it->to);
            segs.erase(it++);
            found = true;
          } else if (it->to == node_list.front()) {
            node_list.insert(node_list.begin(), it->from);
            segs.erase(it++);
            found = true;
          } else {
            ++it;
          }
        }
        if (!found) break;
      }
      node_lists.push_back(node_list);
    }

    vector<uint64_t> ids; ids.reserve(node_lists.size());
    bool orig_id_used = false;
    for (list<list<uint32_t> >::iterator it = node_lists.begin();
        it != node_lists.end(); ++it) {
      uint64_t way_id;
      int sid;
      if (orig_id_used) {
        way_id = d->new_way_id++;
      } else {
        way_id = id;
        orig_id_used = true;
      }
      ids.push_back(way_id);

      fprintf(d->ways, "\"" F_U64 "\",", way_id);
      write_csv_col(d->ways, user_id, ',');
      write_csv_col(d->ways, timestamp, '\n');

      sid = 1;
      for (list<uint32_t>::iterator nit = it->begin();
          nit != it->end(); ++nit) {
        fprintf(d->way_nodes, "\"" F_U64 "\",\"" F_U32 "\",\"%i\"\n", way_id, *nit, sid++);
      }
    }

    if (mysql_stmt_execute(load_tags))
      exit_stmt_err(load_tags);

    if (mysql_stmt_store_result(load_tags))
      exit_stmt_err(load_tags);

    bool multiple_parts = ids.size() > 1,
      create_multipolygon = false;

    while (!mysql_stmt_fetch(load_tags)) {
      if (multiple_parts && !create_multipolygon) {
        if (!strcmp(k, "natural")) {
          if (strcmp(v, "coastline")) {
            create_multipolygon = true;
          }
        } else if (!strcmp(k, "waterway")) {
          if (!strcmp(v, "riverbank")) {
            create_multipolygon = true;
          }
        } else if (!strcmp(k, "leisure") || !strcmp(k, "landuse")
            || !strcmp(k, "sport") || !strcmp(k, "amenity")
            || !strcmp(k, "tourism") || !strcmp(k, "building")) {
          create_multipolygon = true;
        }
      }

      for (vector<uint64_t>::iterator it = ids.begin();
          it != ids.end(); ++it) {
        fprintf(d->way_tags, "\"" F_U64 "\",", *it);
        write_csv_col(d->way_tags, k, ',');
        write_csv_col(d->way_tags, v, '\n');
      }
    }

    if (multiple_parts && create_multipolygon) {
      uint64_t ent_id = d->new_relation_id++;

      fprintf(d->relations, "\"" F_U64 "\",", ent_id);
      write_csv_col(d->relations, user_id, ',');
      write_csv_col(d->relations, timestamp, '\n');

      fprintf(d->relation_tags,
        "\"" F_U64 "\",\"type\",\"multipolygon\"\n", ent_id);

      for (vector<uint64_t>::iterator it = ids.begin();
          it != ids.end(); ++it) {
        fprintf(d->relation_members,
          "\"" F_U64 "\",\"way\",\"" F_U64 "\",\"\"\n", ent_id, *it);
      }
    }
  }
  if (mysql_errno(d->mysql)) exit_stmt_err(load_tags);

  mysql_stmt_close(load_segs);
  mysql_stmt_close(load_tags);

  mysql_free_result(res);
  free(k);
  free(v);
}

static int read_seg_tags(char **tags, char **k, char **v) {
  if (!**tags) return 0;
  char *i = strchr(*tags, ';');
  if (!i) i = *tags + strlen(*tags);
  char *j = strchr(*tags, '=');
  *k = *tags;
  if (j && j < i) {
    *v = j + 1;
  } else {
    *v = i;
  }
  *tags = *i ? i + 1 : i;
  *i = '\0';
  if (j) *j = '\0';
  return 1;
}

static void mark_tagged_segs(struct data *d) {
  MYSQL_RES *res;
  MYSQL_ROW row;
  MYSQL_STMT *way_tags;
  const char
    way_tags_stmt[] = "SELECT k, v FROM current_way_segments INNER JOIN "
      "current_way_tags ON current_way_segments.id = "
      "current_way_tags.id WHERE segment_id = ?";
  char *wk, *wv;
  const size_t max_tag_len = 1 << 16;
  long long mysql_seg_id;
  unsigned long res_len;
  my_bool res_error;
  MYSQL_BIND in_bind[1], out_bind[1];

  /* F***ing libmysql only support fixed size buffers for string results of
   * prepared statements.  So allocate 65k for the tag key and the tag value
   * and hope it'll suffice. */
  wk = (char *) malloc(max_tag_len);
  wv = (char *) malloc(max_tag_len);

  way_tags = mysql_stmt_init(d->mysql2);
  if (!way_tags) exit_mysql_err(d->mysql2);
  if (mysql_stmt_prepare(way_tags, way_tags_stmt, sizeof(way_tags_stmt)))
    exit_stmt_err(way_tags);

  memset(in_bind, 0, sizeof(in_bind));
  in_bind[0].buffer_type = MYSQL_TYPE_LONGLONG;
  in_bind[0].buffer = (char *) &mysql_seg_id;
  in_bind[0].is_null = 0;
  in_bind[0].length = 0;

  if (mysql_stmt_bind_param(way_tags, in_bind))
    exit_stmt_err(way_tags);

  memset(out_bind, 0, sizeof(out_bind));
  out_bind[0].buffer_type = MYSQL_TYPE_STRING;
  out_bind[0].buffer = wk;
  out_bind[0].is_null = 0;
  out_bind[0].length = &res_len;
  out_bind[0].error = &res_error;
  out_bind[0].buffer_length = max_tag_len;
  out_bind[1].buffer_type = MYSQL_TYPE_STRING;
  out_bind[1].buffer = wv;
  out_bind[1].is_null = 0;
  out_bind[1].length = &res_len;
  out_bind[1].error = &res_error;
  out_bind[1].buffer_length = max_tag_len;
  if (mysql_stmt_bind_result(way_tags, out_bind))
    exit_stmt_err(way_tags);

  if (mysql_query(d->mysql, "SELECT id, tags FROM current_segments "
      "WHERE visible && tags != '' && tags != 'created_by=JOSM'"))
    exit_mysql_err(d->mysql);

  res = mysql_use_result(d->mysql);
  if (!res) exit_mysql_err(d->mysql);

  while ((row = mysql_fetch_row(res))) {
    size_t id = parse<size_t>(row[0]);
    if (d->rem_segs[id]) continue;

    map<string, string> interesting_tags;

    char *tags_it = row[1], *k, *v;
    while (read_seg_tags(&tags_it, &k, &v)) {
      if (strcmp(k, "created_by") &&
          strcmp(k, "tiger:county") &&
          strcmp(k, "tiger:upload_uuid") &&
          strcmp(k, "converted_by") &&
          (strcmp(k, "width") || strcmp(v, "4")) &&
          (strcmp(k, "natural") || strcmp(v, "coastline")) &&
          (strcmp(k, "source") || strncmp(v, "PGS", 3))) {
        interesting_tags.insert(make_pair(string(k), string(v)));
      }
    }

    if (interesting_tags.size() == 0) continue;

    mysql_seg_id = id;

    if (mysql_stmt_execute(way_tags))
      exit_stmt_err(way_tags);

    if (mysql_stmt_store_result(way_tags))
      exit_stmt_err(way_tags);

    while (!mysql_stmt_fetch(way_tags)) {
      for (map<string, string>::iterator it = interesting_tags.find(wk);
          it != interesting_tags.end() && it->first == wk; ++it) {
        if (it->second == wv) {
          interesting_tags.erase(it);
          break;
        }
      }
    }

    if (interesting_tags.size() > 0) {
      d->rem_segs[id] = 1;
      d->tgd_segs[id] = 1;
    }
  }

  mysql_free_result(res);

  mysql_stmt_close(way_tags);
  free(wk);
  free(wv);
}

static void convert_remaining_segs(struct data *d) {
  MYSQL_STMT *load_seg;
  MYSQL_BIND args[1], res[3];
  const size_t max_tag_len = 1 << 16;
  char *tags, timestamp[100];
  char *k, *v;
  char notetmp[1024];
  int user_id;
  long long mysql_id;
  unsigned long res_len;
  my_bool res_error;
  const char load_seg_stmt[] =
    "SELECT user_id, tags, CAST(timestamp AS CHAR) FROM current_segments "
    "WHERE visible && id = ?";

  tags = (char *) malloc(max_tag_len);

  load_seg = mysql_stmt_init(d->mysql);
  if (!load_seg) exit_mysql_err(d->mysql);
  if (mysql_stmt_prepare(load_seg, load_seg_stmt, sizeof(load_seg_stmt)))
    exit_stmt_err(load_seg);

  memset(args, 0, sizeof(args));
  args[0].buffer_type = MYSQL_TYPE_LONGLONG;
  args[0].buffer = (char *) &mysql_id;
  args[0].is_null = 0;
  args[0].length = 0;
  if (mysql_stmt_bind_param(load_seg, args))
    exit_stmt_err(load_seg);

  memset(res, 0, sizeof(res));
  res[0].buffer_type = MYSQL_TYPE_LONG;
  res[0].buffer = (char *) &user_id;
  res[0].is_null = 0;
  res[0].length = 0;
  res[0].error = &res_error;
  res[1].buffer_type = MYSQL_TYPE_STRING;
  res[1].buffer = tags;
  res[1].is_null = 0;
  res[1].length = &res_len;
  res[1].error = &res_error;
  res[1].buffer_length = max_tag_len;
  res[2].buffer_type = MYSQL_TYPE_STRING;
  res[2].buffer = timestamp;
  res[2].is_null = 0;
  res[2].length = &res_len;
  res[2].error = &res_error;
  res[2].buffer_length = sizeof(timestamp);
  if (mysql_stmt_bind_result(load_seg, res))
    exit_stmt_err(load_seg);

  for (size_t seg_id = 0; seg_id < d->segs_len; seg_id++) {
    if (!d->rem_segs[seg_id]) continue;
    const char *what = d->tgd_segs[seg_id] ? "tagged" : "unwayed";
    segment seg = d->segs[seg_id];

    mysql_id = seg_id;
    if (mysql_stmt_execute(load_seg)) exit_stmt_err(load_seg);
    if (mysql_stmt_store_result(load_seg)) exit_stmt_err(load_seg);

    while (!mysql_stmt_fetch(load_seg)) {
      uint64_t way_id = d->new_way_id++;

      fprintf(d->ways, "\"" F_U64 "\",\"%i\",", way_id, user_id);
      write_csv_col(d->ways, timestamp, '\n');

      fprintf(d->way_nodes, "\"" F_U64 "\",\"" F_U32 "\",\"%i\"\n", way_id, seg.from, 1);
      fprintf(d->way_nodes, "\"" F_U64 "\",\"" F_U32 "\",\"%i\"\n", way_id, seg.to, 2);

      char *tags_it = tags;
      bool note = false;
      while (read_seg_tags(&tags_it, &k, &v)) {
        fprintf(d->way_tags, "\"" F_U64 "\",", way_id);
        write_csv_col(d->way_tags, k, ',');
        if(!strcmp(k,"note")) {
          snprintf(notetmp, sizeof(notetmp), "%s; FIXME previously %s segment", v, what);
          note = true;
          write_csv_col(d->way_tags, notetmp, '\n');
        } else {
          write_csv_col(d->way_tags, v, '\n');
        }
      }
      if (!note) {
        sprintf(notetmp, "FIXME previously %s segment", what);
        fprintf(d->way_tags, "\"" F_U64 "\",", way_id);
        write_csv_col(d->way_tags, "note", ',');
        write_csv_col(d->way_tags, notetmp, '\n');
      }
    }
  }

  mysql_stmt_close(load_seg);

  free(tags);
}

static MYSQL *connect_to_mysql(char **argv) {
  MYSQL *mysql = mysql_init(NULL);
  if (!mysql) exit_mysql_err(mysql);

  if (!mysql_real_connect(mysql, argv[1], argv[2], argv[3], argv[4],
      argv[5][0] ? atoi(argv[5]) : 0, argv[6][0] ? argv[6] : NULL, 0))
    exit_mysql_err(mysql);

  if (mysql_set_character_set(mysql, "utf8"))
    exit_mysql_err(mysql);

  return mysql;
}

static void open_file(FILE **f, char *fn) {
  *f = fopen(fn, "w+");
  if (!*f) {
    perror("fopen");
    exit(EXIT_FAILURE);
  }
}

int main(int argc, char **argv) {
  struct data data;
  struct data *d = &data;
  size_t prefix_len;
  char *tempfn;

  if (argc != 8) {
    printf("Usage: 008_remove_segments_helper host user passwd database port socket prefix\n");
    exit(EXIT_FAILURE);
  }

  d->mysql = connect_to_mysql(argv);
  d->mysql2 = connect_to_mysql(argv);

  prefix_len = strlen(argv[7]);
  tempfn = (char *) malloc(prefix_len + 15);
  strcpy(tempfn, argv[7]);

  strcpy(tempfn + prefix_len, "ways");
  open_file(&d->ways, tempfn);

  strcpy(tempfn + prefix_len, "way_nodes");
  open_file(&d->way_nodes, tempfn);

  strcpy(tempfn + prefix_len, "way_tags");
  open_file(&d->way_tags, tempfn);

  strcpy(tempfn + prefix_len, "relations");
  open_file(&d->relations, tempfn);

  strcpy(tempfn + prefix_len, "relation_members");
  open_file(&d->relation_members, tempfn);

  strcpy(tempfn + prefix_len, "relation_tags");
  open_file(&d->relation_tags, tempfn);

  free(tempfn);

  find_maxids(d);
  populate_segs(d);
  convert_ways(d);
  mark_tagged_segs(d);
  convert_remaining_segs(d);

  mysql_close(d->mysql);
  mysql_close(d->mysql2);

  fclose(d->ways);
  fclose(d->way_nodes);
  fclose(d->way_tags);

  fclose(d->relations);
  fclose(d->relation_members);
  fclose(d->relation_tags);

  free(d->segs);
  free(d->rem_segs);
  free(d->tgd_segs);

  exit(EXIT_SUCCESS);
}
