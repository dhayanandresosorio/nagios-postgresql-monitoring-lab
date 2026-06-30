# Proceso seguido

## 1. Preparar las máquinas

Se trabajó con dos máquinas Ubuntu dentro de la misma red:

~~~text
Servidor PostgreSQL: 192.168.14.50
Cliente Nagios:      192.168.14.27
~~~

La idea fue que Nagios pudiera comprobar PostgreSQL de forma remota.

Antes de configurar Nagios, es importante comprobar que hay conectividad entre las dos máquinas.

~~~bash
ping 192.168.14.50
~~~

---

## 2. Instalar PostgreSQL en el servidor

En la máquina servidor se instala PostgreSQL:

~~~bash
sudo apt update
sudo apt install -y postgresql postgresql-client
~~~

Después se comprueba el estado del servicio:

~~~bash
systemctl status postgresql
~~~

---

## 3. Permitir conexiones remotas

En `postgresql.conf` se permite que PostgreSQL escuche conexiones externas.

~~~conf
listen_addresses = '*'
port = 5432
~~~

En `pg_hba.conf` se permite la conexión desde el cliente Nagios:

~~~conf
host    nagiosdatabase    nagios_monitor    192.168.14.27/32    scram-sha-256
~~~

Después se reinicia PostgreSQL:

~~~bash
sudo systemctl restart postgresql
~~~

---

## 4. Crear usuario y base de datos

Desde PostgreSQL se crea un usuario específico para las comprobaciones de Nagios.

~~~sql
CREATE ROLE nagios_monitor WITH LOGIN PASSWORD 'CHANGE_ME_DB_PASSWORD';
CREATE DATABASE nagiosdatabase OWNER nagios_monitor;
~~~

Para un entorno real habría que ajustar privilegios con más detalle, pero para esta práctica sirve como base.

---

## 5. Instalar Nagios

En la máquina cliente se instala Nagios con Apache, PHP y plugins.

~~~bash
sudo apt update
sudo apt install -y nagios4 apache2 php libapache2-mod-php nagios-plugins
~~~

Se activa CGI y se reinicia Apache:

~~~bash
sudo a2enmod cgi
sudo systemctl restart apache2
~~~

Se crea el usuario del panel web:

~~~bash
sudo htpasswd -c /etc/nagios4/htpasswd.users nagiosadmin
~~~

---

## 6. Comprobar acceso al panel

El panel de Nagios se accede desde el navegador:

~~~text
http://localhost/nagios4
~~~

Captura relacionada:

![Panel de Nagios](../img/nagios.png)

---

## 7. Probar check_pgsql

Antes de meter la comprobación en Nagios, conviene probar el plugin a mano.

~~~bash
/usr/lib/nagios/plugins/check_pgsql -H 192.168.14.50 -p 5432 -U nagios_monitor -d nagiosdatabase
~~~

Si responde correctamente, ya se puede pasar a la configuración de host y servicio.

---

## 8. Configurar .pgpass

Para que Nagios pueda conectarse sin meter la contraseña en el comando, se usa `.pgpass`.

~~~text
192.168.14.50:5432:nagiosdatabase:nagios_monitor:CHANGE_ME_DB_PASSWORD
~~~

Permisos:

~~~bash
sudo chown nagios:nagios /var/lib/nagios/.pgpass
sudo chmod 600 /var/lib/nagios/.pgpass
~~~

---

## 9. Crear configuración de Nagios

En este repo los ejemplos están separados en:

~~~text
config/nagios/
~~~

Archivos principales:

~~~text
commands-postgresql.cfg.example
host-postgresql.cfg.example
services-postgresql.cfg.example
~~~

La idea es separar comandos, host y servicios para que sea más fácil de mantener.

---

## 10. Validar configuración

Antes de reiniciar Nagios:

~~~bash
sudo nagios4 -v /etc/nagios4/nagios.cfg
~~~

Captura relacionada:

![Validación de Nagios](../img/sudo-nagios4.png)

Después se reinicia el servicio:

~~~bash
sudo systemctl restart nagios4
~~~

Captura relacionada:

![Estado de Nagios](../img/systemctl-status-nagios4.png)

---

## 11. Revisar checks desde el panel

Desde el panel de Nagios se comprueban los servicios configurados.

Capturas de la práctica:

![Nagios check 1](../img/1.png)

![Nagios check 2](../img/2.png)

![Nagios check 3](../img/3.png)

![Nagios check 4](../img/4.png)

![Nagios check 5](../img/5.png)

---

## 12. Resultado

El resultado final es un entorno donde Nagios puede comprobar un PostgreSQL remoto, validar el estado del servicio y mostrar el resultado desde su panel web.

Este tipo de práctica es útil para administración de sistemas porque mezcla servicios Linux, PostgreSQL, monitorización, configuración de checks, permisos y validación de errores.
