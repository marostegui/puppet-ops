# = Class: ores::web
# Sets up a uwsgi based web server for ORES running python3
class ores::web(
    $workers_per_core = 4,
) {
    require ores::base

    uwsgi::app { 'ores-web':
        settings => {
            uwsgi => {
                plugins     => 'python3, router_redirect',
                'wsgi-file' => "${ores::base::config_path}/ores_wsgi.py",
                master      => true,
                chdir       => $ores::base::config_path,
                http-socket => '0.0.0.0:8080',
                venv        => $ores::base::venv_path,
                processes   => inline_template("<%= @processorcount.to_i * ${workers_per_core} %>"),
                # lint:ignore:single_quote_string_with_variables
                route-if    => 'equal:${HTTP_X_FORWARDED_PROTO};http redirect-permanent:https://${HTTP_HOST}${REQUEST_URI}',
                # lint:endignore
                logformat   => '[pid: %(pid)] %(addr) (%(user)) {%(vars) vars in %(pktsize) bytes} [%(ctime)] %(method) %(uri) => generated %(rsize) bytes in %(msecs) msecs (%(proto) %(status)) %(headers) headers in %(hsize) bytes (%(switches) switches on core %(core)) user agent "%(uagent)"',
            }
        }
    }
}
