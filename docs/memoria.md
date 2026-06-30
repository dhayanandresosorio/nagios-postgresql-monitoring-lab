# Memoria técnica - Monitorización de PostgreSQL con Nagios

## 1. Punto de partida

Esta práctica consistió en configurar Nagios para monitorizar un servidor PostgreSQL remoto.

La idea fue montar una máquina servidor con PostgreSQL y una máquina cliente con Nagios. Desde Nagios se hicieron comprobaciones sobre el estado del servidor, el puerto de PostgreSQL y la base de datos.

También se añadió una comprobación más avanzada con `check_postgres` para revisar el número de conexiones activas.

---

## 2. Escenario utilizado

El escenario se montó con dos máquinas Ubuntu dentro de la misma red.

~~~text
Servidor PostgreSQL: 192.168.14.50
Cliente Nagios:      192.168.14.27
Base de datos:       nagiosdatabase
Usuario PostgreSQL:  nagios_monitor
~~~

Las IPs son de laboratorio y se pueden adaptar a otro entorno.

---

## 3. Configuración de PostgreSQL

En el servidor se instaló PostgreSQL:

~~~bash
sudo apt update
sudo apt install -y postgresql postgresql-client
~~~

Después se revisó el servicio:

~~~bash
systemctl status postgresql
~~~

Para permitir conexiones desde Nagios, se modificó `postgresql.conf`.

~~~conf
listen_addresses = '*'
port = 5432
~~~

También se añadió una regla en `pg_hba.conf`.

~~~conf
host    nagiosdatabase    nagios_monitor    192.168.14.27/32    scram-sha-256
~~~

Después de cambiar la configuración se reinició PostgreSQL.

~~~bash
sudo systemctl restart postgresql
~~~

---

## 4. Usuario y base de datos para Nagios

Desde `psql` se creó un usuario de monitorización y una base de datos de prueba.

~~~sql
CREATE ROLE nagios_monitor WITH LOGIN PASSWORD 'CHANGE_ME_DB_PASSWORD';
CREATE DATABASE nagiosdatabase OWNER nagios_monitor;
~~~

La contraseña real no se publica en el repositorio.

---

## 5. Instalación de Nagios

En la máquina cliente se instaló Nagios junto con Apache, PHP y los plugins básicos.

~~~bash
sudo apt update
sudo apt install -y nagios4 apache2 php libapache2-mod-php nagios-plugins
~~~

También se activó el módulo CGI de Apache:

~~~bash
sudo a2enmod cgi
sudo systemctl restart apache2
~~~

Para entrar al panel web, se creó el usuario `nagiosadmin`.

~~~bash
sudo htpasswd -c /etc/nagios4/htpasswd.users nagiosadmin
~~~

---

## 6. Acceso al panel web

El panel web de Nagios se revisó desde el navegador:

~~~text
http://localhost/nagios4
~~~

Desde ahí se puede ver el estado de hosts, servicios y comprobaciones.

---

## 7. Configuración de host y servicio

Para monitorizar PostgreSQL, se define un host con la IP del servidor.

Archivo de ejemplo:

~~~text
config/nagios/host-postgresql.cfg.example
~~~

También se define un servicio para comprobar PostgreSQL con `check_pgsql`.

Archivo de ejemplo:

~~~text
config/nagios/services-postgresql.cfg.example
~~~

---

## 8. Uso de check_pgsql

`check_pgsql` permite comprobar si Nagios puede conectarse al servicio PostgreSQL.

Ejemplo:

~~~bash
/usr/lib/nagios/plugins/check_pgsql -H 192.168.14.50 -p 5432 -U nagios_monitor -d nagiosdatabase
~~~

Para no dejar la contraseña dentro del comando, se usa `.pgpass`.

---

## 9. Uso de .pgpass

El archivo `.pgpass` se crea para el usuario que ejecuta Nagios.

Ruta:

~~~text
/var/lib/nagios/.pgpass
~~~

Contenido de ejemplo:

~~~text
192.168.14.50:5432:nagiosdatabase:nagios_monitor:CHANGE_ME_DB_PASSWORD
~~~

Permisos:

~~~bash
sudo chown nagios:nagios /var/lib/nagios/.pgpass
sudo chmod 600 /var/lib/nagios/.pgpass
~~~

Este punto es importante porque evita poner la contraseña directamente en `commands.cfg`.

---

## 10. Configuración de commands.cfg

En Nagios se puede definir un comando personalizado para PostgreSQL.

Ejemplo:

~~~text
config/nagios/commands-postgresql.cfg.example
~~~

Ahí se separan dos comprobaciones:

- `check_pgsql_remote`: comprueba conexión básica a PostgreSQL.
- `check_postgres_backends`: comprueba conexiones activas usando `check_postgres`.

---

## 11. Plugin check_postgres

Para una comprobación más avanzada se utilizó `check_postgres.pl`.

Este plugin permite revisar métricas específicas de PostgreSQL, como conexiones activas.

Ejemplo:

~~~bash
sudo -u nagios /usr/lib/nagios/plugins/check_postgres.pl \
    --action=backends \
    --host=192.168.14.50 \
    --db=nagiosdatabase \
    --dbuser=nagios_monitor \
    --warning=5 \
    --critical=10
~~~

Con esto se puede generar un estado `WARNING` o `CRITICAL` según el número de conexiones.

---

## 12. Validación de configuración

Antes de reiniciar Nagios, se valida la configuración.

~~~bash
sudo nagios4 -v /etc/nagios4/nagios.cfg
~~~

Después se reinicia el servicio:

~~~bash
sudo systemctl restart nagios4
~~~

---

## 13. Pruebas realizadas

En la práctica se probaron diferentes estados:

- servicio PostgreSQL disponible;
- conexión correcta desde Nagios;
- comprobación mediante `.pgpass`;
- validación de configuración;
- estado OK;
- estado WARNING al superar cierto número de conexiones;
- estado CRITICAL al superar el límite crítico.

Las capturas se conservan en la carpeta `img/`.

---

## 14. Qué me llevo de esta práctica

Esta práctica me sirvió para entender mejor cómo se monitoriza un servicio real desde Nagios.

No fue solo instalar Nagios. También hubo que preparar PostgreSQL para aceptar conexiones remotas, crear un usuario de monitorización, configurar `.pgpass`, crear comandos personalizados y revisar errores de configuración antes de reiniciar el servicio.

Me parece una práctica útil para perfil de sistemas porque mezcla administración Linux, PostgreSQL, monitorización, servicios, permisos y comprobaciones.
