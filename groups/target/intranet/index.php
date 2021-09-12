<html>

<head>
    <meta charset="UTF-8">
    <title>Données internes</title>
</head>

<body>

    Clients :<br>

    <?php
    readfile("/var/www/html/clients.txt");
    ?>

    Compta :<br>
    <?php
    readfile("/var/www/html/compta.txt");
    ?>

</body>

</html>