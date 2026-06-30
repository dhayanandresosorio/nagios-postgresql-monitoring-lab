# Memoria técnica - Monitorización de PostgreSQL con Nagios

## 1. Punto de partida

Esta práctica consistió en configurar Nagios para monitorizar un servidor PostgreSQL remoto.

La idea fue separar el entorno en dos máquinas:

~~~text
Servidor PostgreSQL
Cliente Nagios
~~~

Desde la máquina Nagios se comprueba si PostgreSQL está disponible, si acepta conexiones y si la base de datos responde correctamente.

También se añadió una comprobación más avanzada con `check_postgres`, orientada a revisar el número de conexiones activas.

---

## 2. Escenario utilizado

~~~text
Servidor PostgreSQL: 192.168.14.50
Cliente Nagios:      192.168.14.27
Base de datos:       nagiosdatabase
Usuario PostgreSQL:  nagios_monitor
~~~

Las IPs son de laboratorio y se pueden adaptar a otro entorno.

---

## 3. Configuración de PostgreSQL

En el servidor se instala PostgreSQL:

~~~bash
sudo apt update
sudo apt install -y postgresql postgresql-client
~~~

Después se comprueba el servicio:

~~~bash
systemctl status postgresql
~~~

Para permitir conexiones desde Nagios, se revisa `postgresql.conf`.

~~~conf
listen_addresses = '*'
port = 5432
~~~

También se añade una regla en `pg_hba.conf` para permitir el acceso desde el cliente Nagios:

~~~conf
host    nagiosdatabase    nagios_monitor    192.168.14.27/32    scram-sha-256
~~~

Después de cambiar la configuración, se reinicia PostgreSQL:

~~~bash
sudo systemctl restart postgresql
~~~

---

## 4. Usuario y base de datos de monitorización

Desde `psql` se crea un usuario específico para Nagios.

~~~sql
CREATE ROLE nagios_monitor WITH LOGIN PASSWORD 'CHANGE_ME_DB_PASSWORD';
CREATE DATABASE nagiosdatabase OWNER nagios_monitor;
~~~

La contraseña real no se publica en el repositorio.

---

## 5. Instalación de Nagios

En la máquina cliente se instala Nagios junto con Apache, PHP y los plugins básicos.

~~~bash
sudo apt update
sudo apt install -y nagios4 apache2 php libapache2-mod-php nagios-plugins
~~~

También se activa el módulo CGI de Apache:

~~~bash
sudo a2enmod cgi
sudo systemctl restart apache2
~~~

Para entrar al panel web se crea el usuario `nagiosadmin`.

~~~bash
sudo htpasswd -c /etc/nagios4/htpasswd.users nagiosadmin
~~~

---

## 6. Configuración de host y servicios

Para monitorizar PostgreSQL se define un host con la IP del servidor.

Archivo de ejemplo:

~~~text
config/nagios/host-postgresql.cfg.example
~~~

También se definen servicios para comprobar PostgreSQL:

~~~text
config/nagios/services-postgresql.cfg.example
~~~

Las comprobaciones principales son:

~~~text
PostgreSQL - Puerto y conexión
PostgreSQL - Conexiones activas
~~~

---

## 7. Uso de check_pgsql

`check_pgsql` permite comprobar si Nagios puede conectarse al servicio PostgreSQL.

Ejemplo:

~~~bash
/usr/lib/nagios/plugins/check_pgsql -H 192.168.14.50 -p 5432 -U nagios_monitor -d nagiosdatabase
~~~

Este check sirve para validar conectividad, autenticación y respuesta básica de la base de datos.

---

## 8. Uso de .pgpass

Para no dejar la contraseña directamente en `commands.cfg`, se utiliza `.pgpass`.

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

Este punto es importante porque permite que Nagios ejecute checks contra PostgreSQL sin publicar la contraseña en el comando.

---

## 9. Uso de check_postgres

Para una comprobación más avanzada se utiliza `check_postgres.pl`.

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

Con esto se pueden generar estados `WARNING` o `CRITICAL` según el número de conexiones activas.

---

## 10. Validación de configuración

Antes de reiniciar Nagios, se valida la configuración.

~~~bash
sudo nagios4 -v /etc/nagios4/nagios.cfg
~~~

Después se reinicia el servicio:

~~~bash
sudo systemctl restart nagios4
~~~

---

## 11. Pruebas realizadas

Durante la práctica se comprobaron estos puntos:

- servicio PostgreSQL disponible;
- conexión correcta desde Nagios;
- comprobación mediante `.pgpass`;
- validación de configuración;
- estado OK;
- estado WARNING;
- estado CRITICAL.

Las capturas se conservan en la carpeta `img/`.

---

## 12. Qué me llevo de esta práctica

Esta práctica me sirvió para entender mejor cómo se monitoriza un servicio real desde Nagios.

No fue solo instalar Nagios. También hubo que preparar PostgreSQL para aceptar conexiones remotas, crear un usuario de monitorización, configurar `.pgpass`, definir comandos personalizados y revisar errores de configuración antes de reiniciar el servicio.

Me parece una práctica útil para perfil de sistemas porque mezcla administración Linux, PostgreSQL, monitorización, servicios, permisos y comprobaciones.
