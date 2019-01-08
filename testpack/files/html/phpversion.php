<?php
$ver = phpversion();
if ( preg_match("/^7\.3\..*$/", $ver))
{
  echo "Success";
} else {
  echo "Failure";
}

?>
