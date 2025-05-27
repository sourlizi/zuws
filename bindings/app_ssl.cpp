#define ZUWS_SSL true
#include "app.ixx"

uws_app_t *uws_create_app_ssl(ssl_options_t options)
{
    uWS::SocketContextOptions opts;
    opts.key_file_name = options.key_file_name;
    opts.cert_file_name = options.cert_file_name;
    opts.passphrase = options.passphrase;
    opts.dh_params_file_name = options.dh_params_file_name;
    opts.ca_file_name = options.ca_file_name;
    opts.ssl_ciphers = options.ssl_ciphers;
    opts.ssl_prefer_low_memory_usage = options.ssl_prefer_low_memory_usage;
    return (uws_app_t *)new uWS::SSLApp(opts);
}
