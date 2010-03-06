Sanitize::Config::OSM = Sanitize::Config::RELAXED.dup

Sanitize::Config::OSM[:add_attributes] = { 'a' => { 'rel' => 'nofollow' } }
