# base docker image  

`docker run`时如果配置了`SESSION_DOMAIN`环境变量 会修改`context.xml`的`sessionCookieDomain`参数值,否则为localhost

