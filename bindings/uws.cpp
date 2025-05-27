#include "uws.h"
#include "App.h"

#pragma region uWS-Request

bool uws_req_is_ancient(uws_req_t *res)
{
    return ((uWS::HttpRequest *)res)->isAncient();
}

bool uws_req_get_yield(uws_req_t *res)
{
    return ((uWS::HttpRequest *)res)->getYield();
}

void uws_req_set_yield(uws_req_t *res, bool yield)
{
    return ((uWS::HttpRequest *)res)->setYield(yield);
}

void uws_req_for_each_header(uws_req_t *res, uws_get_headers_server_handler handler)
{
    for (auto header : *((uWS::HttpRequest *)res))
    {
        handler(header.first.data(), header.first.length(), header.second.data(), header.second.length());
    }
}

size_t uws_req_get_url(uws_req_t *res, const char **dest)
{
    std::string_view value = ((uWS::HttpRequest *)res)->getUrl();
    *dest = value.data();
    return value.length();
}

size_t uws_req_get_full_url(uws_req_t *res, const char **dest)
{
    std::string_view value = ((uWS::HttpRequest *)res)->getFullUrl();
    *dest = value.data();
    return value.length();
}

size_t uws_req_get_method(uws_req_t *res, const char **dest)
{
    std::string_view value = ((uWS::HttpRequest *)res)->getMethod();
    *dest = value.data();
    return value.length();
}

size_t uws_req_get_case_sensitive_method(uws_req_t *res, const char **dest)
{
    std::string_view value = ((uWS::HttpRequest *)res)->getCaseSensitiveMethod();
    *dest = value.data();
    return value.length();
}

size_t uws_req_get_header(uws_req_t *res, const char *lower_case_header, size_t lower_case_header_length, const char **dest)
{
    std::string_view value = ((uWS::HttpRequest *)res)->getHeader(std::string_view(lower_case_header, lower_case_header_length));
    *dest = value.data();
    return value.length();
}

size_t uws_req_get_query(uws_req_t *res, const char *key, size_t key_length, const char **dest)
{
    std::string_view value = ((uWS::HttpRequest *)res)->getQuery(std::string_view(key, key_length));
    *dest = value.data();
    return value.length();
}

size_t uws_req_get_parameter_name(uws_req_t *res, const char *key, size_t key_length, const char **dest)
{
    std::string_view value = ((uWS::HttpRequest *)res)->getParameter(std::string_view(key, key_length));
    *dest = value.data();
    return value.length();
}

size_t uws_req_get_parameter_index(uws_req_t *res, unsigned short index, const char **dest)
{
    std::string_view value = ((uWS::HttpRequest *)res)->getParameter(index);
    *dest = value.data();
    return value.length();
}

#pragma endregion

void uws_loop_defer(us_loop_t *loop, void(cb()))
{
    ((uWS::Loop *)loop)->defer([cb]()
                               { cb(); });
}

struct us_loop_t *uws_get_loop()
{
    return (struct us_loop_t *)uWS::Loop::get();
}

struct us_loop_t *uws_get_loop_with_native(void *existing_native_loop)
{
    return (struct us_loop_t *)uWS::Loop::get(existing_native_loop);
}