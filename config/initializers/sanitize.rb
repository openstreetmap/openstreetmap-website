Sanitize::Config::OSM = Sanitize::Config::RELAXED.dup

Sanitize::Config::OSM[:elements] -= [ 'div', 'style' ]
Sanitize::Config::OSM[:add_attributes] = { 'a' => { 'rel' => 'nofollow' } }
Sanitize::Config::OSM[:remove_contents] = [ 'script', 'style' ]
