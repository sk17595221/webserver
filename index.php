<html>
<body>
<h1>WELCOME TO MY WEBSITE</h1>
<h3>lets have fun</h3>
<?php
   $cloudant_url=`head -n1 path.txt`;
   $img_path="https://".$cloudant_url."/terraform.png";
   echo "<br>";
   echo "<img src='${img_path}' width=100 height=100>";
?>
</body> 
</html> 
