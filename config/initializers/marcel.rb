# frozen_string_literal: true

Marcel::MimeType.extend "application/x-bzip2",
                        :extensions => %w[bz2 tbz2 boz],
                        :magic => [
                          [0, "BZh1"],
                          [0, "BZh2"],
                          [0, "BZh3"],
                          [0, "BZh4"],
                          [0, "BZh5"],
                          [0, "BZh6"],
                          [0, "BZh7"],
                          [0, "BZh8"],
                          [0, "BZh9"]
                        ]
