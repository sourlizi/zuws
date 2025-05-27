#define ZUWS_SSL false
#include "app.ixx"


uws_app_t *uws_create_app()
{
    return (uws_app_t *)new uWS::App();
}
