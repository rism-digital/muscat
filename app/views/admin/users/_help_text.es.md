## Cóm funcionan las notificaciones

Se pueden crear notificaciones para recibir alertas por correo cuando se crean o editan registros que correspongan con sus reglas de búsqueda.

Introduzca estas reglas en el campo de notificaciones.

La estructura de cada regla es: nombre del campo, dos puntos, y el término de búsqueda. Vigile que no haya ningún espacio después de los dos puntos. En este ejemplo, se generará una notificación cada vez que es guarde un registro con la sigla de la biblioteca CH:BE1.

```
lib_siglum:CH-BEl
```

Introduzca cada regla en una linea diferente:

```
lib_siglum:CH-BEl
composer:Bach
```

Ésta implica que recibirá una notificación por cada registro de fuentes que tenga como sigla de biblioteca CH-BE1, y oltra para cada registro de fuentes del compositor Bach.

Puede combinar reglas escribiéndolas en una misma linia, separadas per un espacio:

```
lib_siglum:CH* composer:Bach*
```

Ésta encontrará cambios en todos los registros de fonte que tengan una sigla de biblioteca que empiece por CH y un compositor que empiece por Bach.

Las reglas se pueden repetir en la lista de notificaciones, pero se evaluarán por separado. Por ejemplo:

```
lib_siglum:CH* composer:Bach*
lib_siglum:CH*
```

En este caso, recibirá notificaciones para todos los registros de fuentes de CH que tengan como compositor Bach, y, además, notificaciones para todos los registros de funete de CH:

### Categorías de búsqueda

Por defecto, las reglas se aplican a los registros de fuentes. Pero también se puden crear para registros de autoridad, especificándolo al principio de la regla y seguida de un espacio, por ejemplo:

```
work composer:Bach*
institution name:British*
```

Cada regla sólo puede buscar una categoría.

### Asteriscos y espacios

Las reglas pueden incluir asteriscos para permitir truncamientos:

```
lib_siglum:CH*
```

Esta regla crea una notificación para cada registro de fuente en la que la sigla de la biblioteca comience por CH.

Los términos de búsqueda que tengan espacios se deben escribir entre comillas.

```
composer:"Bach, Johann Sebastian";
```

o

```
composer:"Bach, Johann*";
```

Si no hubiera comillas, sólo se buscaría la primera palabra, y las demás serían ingoradas. Tenga en cuenta que el nombre del campo no está incluido en las comillas.

### Catetorías y camps disponibles:

#### Registros de fuente (valor por defecto)

* **lib\_siglum** _Sigla de biblioteca (852 $a)_
* **shelf\_mark** _Topográfico (852 $c)_
* **composer** _Compositor/autor (100 $a)_
* **std\_title** _Título uniforme (240 $a)_
* **title** _Título propio (245 $a)_
* **record\_type** _tipo de plantilla_:
    * collection (registro madre para manuscrits, libretos o tratados)
    * source (manuscritos, menos los de colección)
    * edition (ediciones de música impresa, menos las entradas individuales)
    * edition\_content (entradas individuales de una edición impresa)
    * libretto\_source (libretos manuscritos, menos los registres de colección)
    * libretto\_edition (libretos impresos, menos las entradas individuales)
    * libretto\_edition\_content (entradas individuales en libretos impresos)
    * theoretica\_source (tratados manuscritos, excepto los registres de colección)
    * theoretica\_edition (tratados impresos, menos las entrades individuales) 
    * theoretica\_edition\_content (entradas individuales en un tratado impreso)
    * composite\_volume

Ejemplo:

```
record_type:edition lib_siglum:CH* composer:Bach* std_title:"6 Fugues";
```

### Obras

- **composer** _Nombre del compositor (100 $a)_
- **title** _Título de la obra (100 $t)_

Ejemplo:

```
work composer: "Bach, Albert*"
```

### Instituciones

- **name** _Forma autorizada del nombre de la institución (110 $a)_
- **place** _Ciudad de la institución (110 $c)_
- **siglum** _Sigla de la institución (110 $g)_
- **address** _Dirección de la institución (371 $a)_
- **alternates** _Nombres alternativos (510 or 410)_
- **notes** _Cualquer palabra en el campo de notas (680 $a)_

Ejemplo:

```
institution name:Universitätsbibliothek*
```

### Cadencia de las notificaciones

En el desplegable _Cadencia de las notificaciones_ puede escoger la cadencia respecto a cuado prefiere que se le notifique:

- **cada vez** Enviar una notificación cada vez que es guarde un registre (con un período de gracia de una hora cuando un registro es guarda más de una vez por la misma persona).
- **cada dia** La lista de los registres modificados se envía una vez al día.
- **cada semana** La llista de los registros modificados se envía un vez a la semana.
- **desactivades** Las notificationes están desactivadas.
