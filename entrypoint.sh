#!/bin/bash -e
domain=${SESSION_DOMAIN:-localhost}
sed -i "s/{{domain}}/$domain/g" /usr/local/tomcat/conf/context.xml
tmp=${MISC_EXTERNAL_ENDPOINT}
tmp=${tmp#*//}
misc_external_domain=${tmp%%:*}
tmp=${MISC_INTERNAL_ENDPOINT}
tmp=${tmp#*//}
misc_internal_domain=${tmp%%:*}
tmp=${BBS_EXTERNAL_ENDPOINT}
tmp=${tmp#*//}
bbs_domain=${tmp%%:*}
sed -i "s/{{misc_external_domain}}/$misc_external_domain/g" /etc/nginx/conf.d/default.conf
sed -i "s/{{misc_internal_domain}}/$misc_internal_domain/g" /etc/nginx/conf.d/default.conf
sed -i "s/{{bbs_domain}}/$bbs_domain/g" /etc/nginx/conf.d/default.conf
exec "$@"
