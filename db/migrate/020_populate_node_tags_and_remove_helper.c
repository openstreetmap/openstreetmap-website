#include <mysql.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void exit_mysql_err(MYSQL *mysql) {
  const char *err = mysql_error(mysql);
  if (err) {
    fprintf(stderr, "019_populate_node_tags_and_remove_helper: MySQL error: %s\n", err);
  } else {
    fprintf(stderr, "019_populate_node_tags_and_remove_helper: MySQL error\n");
  }
  abort();
  exit(EXIT_FAILURE);
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

static void unescape(char *str) {
  char *i = str, *o = str, tmp;

  while (*i) {
    if (*i == '\\') {
      i++;
      switch (tmp = *i++) {
        case 's': *o++ = ';'; break;
        case 'e': *o++ = '='; break;
        case '\\': *o++ = '\\'; break;
        default: *o++ = tmp; break;
      }
    } else {
      *o++ = *i++;
    }
  }
}

static int read_node_tags(char **tags, char **k, char **v) {
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

  unescape(*k);
  unescape(*v);

  return 1;
}

struct data {
  MYSQL *mysql;
  size_t version_size;
  uint16_t *version;
};

static void proc_nodes(struct data *d, const char *tbl, FILE *out, FILE *out_tags, int hist) {
  MYSQL_RES *res;
  MYSQL_ROW row;
  char query[256];

  snprintf(query, sizeof(query),  "SELECT id, latitude, longitude, "
      "user_id, visible, tags, timestamp, tile FROM %s", tbl);
  if (mysql_query(d->mysql, query))
    exit_mysql_err(d->mysql);

  res = mysql_use_result(d->mysql);
  if (!res) exit_mysql_err(d->mysql);

  while ((row = mysql_fetch_row(res))) {
    unsigned long id = strtoul(row[0], NULL, 10);
    uint32_t version;

    if (id >= d->version_size) {
      fprintf(stderr, "preallocated nodes size exceeded");
      abort();
    }

    if (hist) {
      version = ++(d->version[id]);

      fprintf(out, "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%u\"\n",
        row[0], row[1], row[2], row[3], row[4], row[6], row[7], version);
    } else {
      /*fprintf(out, "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n",
	row[0], row[1], row[2], row[3], row[4], row[6], row[7]);*/
    }

    char *tags_it = row[5], *k, *v;
    while (read_node_tags(&tags_it, &k, &v)) {
      if (hist) {
        fprintf(out_tags, "\"%s\",\"%u\",", row[0], version);
      } else {
        fprintf(out_tags, "\"%s\",", row[0]);
      }

      write_csv_col(out_tags, k, ',');
      write_csv_col(out_tags, v, '\n');
    }
  }
  if (mysql_errno(d->mysql)) exit_mysql_err(d->mysql);

  mysql_free_result(res);
}

static size_t select_size(MYSQL *mysql, const char *q) {
  MYSQL_RES *res;
  MYSQL_ROW row;
  size_t ret;

  if (mysql_query(mysql, q))
    exit_mysql_err(mysql);

  res = mysql_store_result(mysql);
  if (!res) exit_mysql_err(mysql);

  row = mysql_fetch_row(res);
  if (!row) exit_mysql_err(mysql);

  if (row[0]) {
    ret = strtoul(row[0], NULL, 10);
  } else {
    ret = 0;
  }

  mysql_free_result(res);

  return ret;
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
  size_t prefix_len;
  FILE *current_nodes, *current_node_tags, *nodes, *node_tags;
  char *tempfn;
  struct data data, *d = &data;

  if (argc != 8) {
    printf("Usage: 019_populate_node_tags_and_remove_helper host user passwd database port socket prefix\n");
    exit(EXIT_FAILURE);
  }

  d->mysql = connect_to_mysql(argv);

  d->version_size = 1 + select_size(d->mysql, "SELECT max(id) FROM current_nodes");
  d->version = (uint16_t *) malloc(sizeof(uint16_t) * d->version_size);
  if (!d->version) {
    perror("malloc");
    abort();
    exit(EXIT_FAILURE);
  }
  memset(d->version, 0, sizeof(uint16_t) * d->version_size);

  prefix_len = strlen(argv[7]);
  tempfn = (char *) malloc(prefix_len + 32);
  strcpy(tempfn, argv[7]);

  strcpy(tempfn + prefix_len, "current_nodes");
  open_file(&current_nodes, tempfn);

  strcpy(tempfn + prefix_len, "current_node_tags");
  open_file(&current_node_tags, tempfn);

  strcpy(tempfn + prefix_len, "nodes");
  open_file(&nodes, tempfn);

  strcpy(tempfn + prefix_len, "node_tags");
  open_file(&node_tags, tempfn);

  free(tempfn);

  proc_nodes(d, "nodes", nodes, node_tags, 1);
  proc_nodes(d, "current_nodes", current_nodes, current_node_tags, 0);

  free(d->version);

  mysql_close(d->mysql);

  fclose(current_nodes);
  fclose(current_node_tags);
  fclose(nodes);
  fclose(node_tags);

  exit(EXIT_SUCCESS);
}
