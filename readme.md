#Ejecución:
##inicar deployment
`terraform apply`
##Eliminar deployment
`terraform destroy`


#Variables:
* TF_VAR_nodes: Define el numero de nodos minio a levantar. Default: `4`
* TF_VAR_ebs_size: Define el tamaño en GB para data de cada nodo minio. Default: `50`
* TF_VAR_MINIO_ACCESS_KEY: Define ACCESS_KEY. Default: `CZPSXR0VS1JXMVX7PRUE`
* TF_VAR_MINIO_SECRET_KEY:Define SECRET_KEY. Default: `84znI0cO+BC1fOzkzC7of4yfa6lViXlzx6zRQCgw`

Ejemplo:
`TF_VAR_nodes=8 TF_VAR_ebs_size=100 terraform apply`

#Output:
Ejemplo de Output.

```
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

MINIO_ACCESS_KEY = CZPSXR0VS1JXMVX7PRUE
MINIO_SECRET_KEY = 84znI0cO+BC1fOzkzC7of4yfa6lViXlzx6zRQCgw
ip_consulio_redis = 35.168.15.199
ip_minio_endpoints = 54.161.117.242,35.153.140.212,54.175.0.92,54.227.215.176,52.205.22.222,34.238.143.63,54.157.28.96,34.207.217.81
```

`ip_consulio_redis`: es la ip que se debe utilizar para conectar el redis de logs de operaciones, en caso que se quieran ejecutar acciones en base este, por ejemplo leer los archivos que se escribieron para inicar la replica a otro servicio de almacenamiento.
 `ip_minio_endpoints`: cualquier de estas ips puede ser usada como endpoint S3 del cluster minio.
 `MINIO_ACCESS_KEY` y `MINIO_SECRET_KEY`: las llaves de acceso para usar minio.


#Descripcion de nodos:
##Nodo control.
Este nodo tiene el servidor de consul donde se registran los nodos minio, y el servidor de redis donde se envian todas las notificaciones sobre el bucket `testbucket`

Este nodo tambien tiene instalada la aplicacion de control `mc` en caso que se quiera realizar alguna operaion de administración con minio console.

##Nodos minio
Estos nodos solo tienen la aplicacion de minio en modo server.
para inicar la app esperan via consul, que existan registrados el numero de nodos totales a los definidos en la variable `TF_VAR_nodes` 

#TODO
* Poner dentro de variables la zona a levantar, por ahora levanta todo en us-east-1
* Mejorar las reglas de firewall, ahora esta todo open.
* Mejorar documentación. (traducir y ordenar.)
* Utilizar templates de terraform y no "echos" en bash.
