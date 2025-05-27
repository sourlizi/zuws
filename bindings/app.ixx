#include "uws.h"

#include "App.h"

#pragma region uWS-app

#if !defined(ZUWS_SSL)
#define ZUWS_SSL false
#endif

#if ZUWS_SSL == true
#define uws_function(name) uws_##name##_ssl
using app_t = uWS::SSLApp;
using app_response_t = uWS::HttpResponse<true>;
using websocket_t = uWS::WebSocket<true, true, void *>;
using websocket_behavior_t = uWS::SSLApp::WebSocketBehavior<void *>;
#else
#define uws_function(name) uws_##name
using app_t = uWS::App;
using app_response_t = uWS::HttpResponse<false>;
using websocket_t = uWS::WebSocket<false, true, void *>;
using websocket_behavior_t = uWS::App::WebSocketBehavior<void *>;
#endif

#define METHOD(name)                                                                                                     \
    void uws_function(app_##name)(uws_app_t * app, const char *pattern, uws_method_handler handler)                      \
    {                                                                                                                    \
        ((app_t *)app)->name(pattern, [handler](auto *res, auto *req) { handler((uws_res_t *)res, (uws_req_t *)req); }); \
    };
HTTP_METHODS
#undef METHOD

void uws_function(app_destroy)(uws_app_t *app)
{
    delete ((app_t *)app);
}

void uws_function(app_run)(uws_app_t *app)
{
    ((app_t *)app)->run();
}

void uws_function(app_listen)(uws_app_t *app, int port, uws_listen_handler handler)
{
    if (!handler)
        handler = [](auto) {};

    ((app_t *)app)->listen(port, [handler](struct us_listen_socket_t *listen_socket)
                           { handler((struct us_listen_socket_t *)listen_socket); });
}

void uws_function(app_close)(uws_app_t *app)
{
    ((app_t *)app)->close();
}

#pragma endregion
#pragma region uWS-Response

void uws_function(res_close)(uws_res_t *res)
{
    ((app_response_t *)res)->close();
}

void uws_function(res_end)(uws_res_t *res, const char *data, size_t length, bool close_connection)
{
    ((app_response_t *)res)->end(std::string_view(data, length), close_connection);
}

void uws_function(res_cork)(uws_res_t *res, void (*callback)(uws_res_t *res))
{
    ((app_response_t *)res)->cork([=]()
                                  { callback(res); });
}

void uws_function(res_pause)(uws_res_t *res)
{
    ((app_response_t *)res)->pause();
}

void uws_function(res_resume)(uws_res_t *res)
{
    ((app_response_t *)res)->resume();
}

void uws_function(res_write_continue)(uws_res_t *res)
{
    ((app_response_t *)res)->writeContinue();
}

void uws_function(res_write_status)(uws_res_t *res, const char *status, size_t length)
{
    ((app_response_t *)res)->writeStatus(std::string_view(status, length));
}

void uws_function(res_write_header)(uws_res_t *res, const char *key, size_t key_length, const char *value, size_t value_length)
{
    ((app_response_t *)res)->writeHeader(std::string_view(key, key_length), std::string_view(value, value_length));
}

void uws_function(res_write_header_int)(uws_res_t *res, const char *key, size_t key_length, uint64_t value)
{
    ((app_response_t *)res)->writeHeader(std::string_view(key, key_length), value);
}

void uws_function(res_end_without_body)(uws_res_t *res, bool close_connection)
{
    ((app_response_t *)res)->endWithoutBody(std::nullopt, close_connection);
}

bool uws_function(res_write)(uws_res_t *res, const char *data, size_t length)
{
    return ((app_response_t *)res)->write(std::string_view(data, length));
}

void uws_function(res_override_write_offset)(uws_res_t *res, uintmax_t offset)
{
    ((app_response_t *)res)->overrideWriteOffset(offset);
}

bool uws_function(res_has_responded)(uws_res_t *res)
{
    return ((app_response_t *)res)->hasResponded();
}

void uws_function(res_on_writable)(uws_res_t *res, uws_res_on_writable_handler handler)
{
    ((app_response_t *)res)->onWritable([handler, res](uintmax_t a)
                                        { return handler(res, a); });
}

void uws_function(res_on_aborted)(uws_res_t *res, uws_res_on_aborted_handler handler)
{
    ((app_response_t *)res)->onAborted([handler, res]
                                       { handler(res); });
}

void uws_function(res_on_data)(uws_res_t *res, uws_res_on_data_handler handler)
{
    ((app_response_t *)res)->onData([handler, res](auto chunk, bool is_end)
                                    { handler(res, chunk.data(), chunk.length(), is_end); });
}

void uws_function(res_upgrade)(uws_res_t *res, void *data, const char *sec_web_socket_key, size_t sec_web_socket_key_length, const char *sec_web_socket_protocol, size_t sec_web_socket_protocol_length, const char *sec_web_socket_extensions, size_t sec_web_socket_extensions_length, uws_socket_context_t *ws)
{
    ((app_response_t *)res)->template upgrade<void *>(data ? std::move(data) : NULL, std::string_view(sec_web_socket_key, sec_web_socket_key_length), std::string_view(sec_web_socket_protocol, sec_web_socket_protocol_length), std::string_view(sec_web_socket_extensions, sec_web_socket_extensions_length), (struct us_socket_context_t *)ws);
}

uws_try_end_result_t uws_function(res_try_end)(uws_res_t *res, const char *data, size_t length, uintmax_t total_size, bool close_connection)
{

    std::pair<bool, bool> result = ((app_response_t *)res)->tryEnd(std::string_view(data, length), total_size);
    return uws_try_end_result_t{
        .ok = result.first,
        .has_responded = result.second,
    };
}

uintmax_t uws_function(res_get_write_offset)(uws_res_t *res)
{
    return ((app_response_t *)res)->getWriteOffset();
}

size_t uws_function(res_get_remote_address)(uws_res_t *res, const char **dest)
{
    std::string_view value = ((app_response_t *)res)->getRemoteAddress();
    *dest = value.data();
    return value.length();
}

size_t uws_function(res_get_remote_address_as_text)(uws_res_t *res, const char **dest)
{
    std::string_view value = ((app_response_t *)res)->getRemoteAddressAsText();
    *dest = value.data();
    return value.length();
}

#pragma endregion
#pragma region uWS-Websockets

#define WEBSOCKET_HANDLER(field, lambda_args, lambda_body)         \
    if (behavior.field)                                            \
    {                                                              \
        auto handler = behavior.field;                             \
        generic_handler.field = [handler] lambda_args lambda_body; \
    }

void uws_function(ws)(uws_app_t *app, const char *pattern, uws_socket_behavior_t behavior)
{
    auto generic_handler = websocket_behavior_t{
        .compression = (uWS::CompressOptions)(uint64_t)behavior.compression,
        .maxPayloadLength = behavior.maxPayloadLength,
        .idleTimeout = behavior.idleTimeout,
        .maxBackpressure = behavior.maxBackpressure,
        .closeOnBackpressureLimit = behavior.closeOnBackpressureLimit,
        .resetIdleTimeoutOnSend = behavior.resetIdleTimeoutOnSend,
        .sendPingsAutomatically = behavior.sendPingsAutomatically,
        .maxLifetime = behavior.maxLifetime,
    };

    WEBSOCKET_HANDLER(upgrade, (auto *res, auto *req, auto *context), {
        handler((uws_res_t *)res, (uws_req_t *)req, (uws_socket_context_t *)context);
    });

    WEBSOCKET_HANDLER(open, (auto *ws), {
        handler((uws_websocket_t *)ws);
    });

    WEBSOCKET_HANDLER(message, (auto *ws, auto message, auto opcode), {
        handler((uws_websocket_t *)ws, message.data(), message.length(), (uws_opcode_t)opcode);
    });

    WEBSOCKET_HANDLER(dropped, (auto *ws, auto message, auto opcode), {
        handler((uws_websocket_t *)ws, message.data(), message.length(), (uws_opcode_t)opcode);
    });

    WEBSOCKET_HANDLER(drain, (auto *ws), {
        handler((uws_websocket_t *)ws);
    });

    WEBSOCKET_HANDLER(ping, (auto *ws, auto message), {
        handler((uws_websocket_t *)ws, message.data(), message.length());
    });

    WEBSOCKET_HANDLER(pong, (auto *ws, auto message), {
        handler((uws_websocket_t *)ws, message.data(), message.length());
    });

    WEBSOCKET_HANDLER(close, (auto *ws, int code, auto message), {
        handler((uws_websocket_t *)ws, code, message.data(), message.length());
    });

    WEBSOCKET_HANDLER(subscription, (auto *ws, auto topic, int subscribers, int old_subscribers), {
        handler((uws_websocket_t *)ws, topic.data(), topic.length(), subscribers, old_subscribers);
    });

    app_t *uwsApp = (app_t *)app;
    uwsApp->ws<void *>(pattern, std::move(generic_handler));
}

void uws_function(ws_close)(uws_websocket_t *ws)
{
    websocket_t *uws = (websocket_t *)ws;
    uws->close();
}

uws_sendstatus_t uws_function(ws_send)(uws_websocket_t *ws, const char *message, size_t length, uws_opcode_t opcode)
{
    websocket_t *uws = (websocket_t *)ws;
    return (uws_sendstatus_t)uws->send(std::string_view(message, length), (uWS::OpCode)(unsigned char)opcode);
}

uws_sendstatus_t uws_function(ws_send_with_options)(uws_websocket_t *ws, const char *message, size_t length, uws_opcode_t opcode, bool compress, bool fin)
{
    websocket_t *uws = (websocket_t *)ws;
    return (uws_sendstatus_t)uws->send(std::string_view(message, length), (uWS::OpCode)(unsigned char)opcode, compress, fin);
}

uws_sendstatus_t uws_function(ws_send_fragment)(uws_websocket_t *ws, const char *message, size_t length, bool compress)
{
    websocket_t *uws = (websocket_t *)ws;
    return (uws_sendstatus_t)uws->sendFragment(std::string_view(message, length), compress);
}

uws_sendstatus_t uws_function(ws_send_first_fragment)(uws_websocket_t *ws, const char *message, size_t length, bool compress)
{
    websocket_t *uws = (websocket_t *)ws;
    return (uws_sendstatus_t)uws->sendFirstFragment(std::string_view(message, length), uWS::OpCode::BINARY, compress);
}

uws_sendstatus_t uws_function(ws_send_first_fragment_with_opcode)(uws_websocket_t *ws, const char *message, size_t length, uws_opcode_t opcode, bool compress)
{
    websocket_t *uws = (websocket_t *)ws;
    return (uws_sendstatus_t)uws->sendFirstFragment(std::string_view(message, length), (uWS::OpCode)(unsigned char)opcode, compress);
}

uws_sendstatus_t uws_function(ws_send_last_fragment)(uws_websocket_t *ws, const char *message, size_t length, bool compress)
{
    websocket_t *uws = (websocket_t *)ws;
    return (uws_sendstatus_t)uws->sendLastFragment(std::string_view(message, length), compress);
}

void uws_function(ws_end)(uws_websocket_t *ws, int code, const char *message, size_t length)
{
    websocket_t *uws = (websocket_t *)ws;
    uws->end(code, std::string_view(message, length));
}

void uws_function(ws_cork)(uws_websocket_t *ws, void (*handler)())
{
    websocket_t *uws = (websocket_t *)ws;
    uws->cork([handler]()
              { handler(); });
}

bool uws_function(ws_subscribe)(uws_websocket_t *ws, const char *topic, size_t length)
{
    websocket_t *uws = (websocket_t *)ws;
    return uws->subscribe(std::string_view(topic, length));
}

bool uws_function(ws_unsubscribe)(uws_websocket_t *ws, const char *topic, size_t length)
{
    websocket_t *uws = (websocket_t *)ws;
    return uws->unsubscribe(std::string_view(topic, length));
}

bool uws_function(ws_is_subscribed)(uws_websocket_t *ws, const char *topic, size_t length)
{
    websocket_t *uws = (websocket_t *)ws;
    return uws->isSubscribed(std::string_view(topic, length));
}

void uws_function(ws_iterate_topics)(uws_websocket_t *ws, void (*callback)(const char *topic, size_t length))
{
    websocket_t *uws = (websocket_t *)ws;
    uws->iterateTopics([callback](auto topic)
                       { callback(topic.data(), topic.length()); });
}

bool uws_function(ws_publish)(uws_websocket_t *ws, const char *topic, size_t topic_length, const char *message, size_t message_length)
{
    websocket_t *uws = (websocket_t *)ws;
    return uws->publish(std::string_view(topic, topic_length), std::string_view(message, message_length));
}

bool uws_function(ws_publish_with_options)(uws_websocket_t *ws, const char *topic, size_t topic_length, const char *message, size_t message_length, uws_opcode_t opcode, bool compress)
{
    websocket_t *uws = (websocket_t *)ws;
    return uws->publish(std::string_view(topic, topic_length), std::string_view(message, message_length), (uWS::OpCode)(unsigned char)opcode, compress);
}

unsigned int uws_function(ws_get_buffered_amount)(uws_websocket_t *ws)
{
    websocket_t *uws = (websocket_t *)ws;
    return uws->getBufferedAmount();
}

size_t uws_function(ws_get_remote_address)(uws_websocket_t *ws, const char **dest)
{
    websocket_t *uws = (websocket_t *)ws;
    std::string_view value = uws->getRemoteAddress();
    *dest = value.data();
    return value.length();
}

size_t uws_function(ws_get_remote_address_as_text)(uws_websocket_t *ws, const char **dest)
{
    websocket_t *uws = (websocket_t *)ws;
    std::string_view value = uws->getRemoteAddressAsText();
    *dest = value.data();
    return value.length();
}

#pragma endregion

#undef ZUWS_SSL