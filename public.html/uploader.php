html>
<head>
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-36563450-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
</head>
<?php
$target_path = "uploads/";

$target_path = $target_path . basename( $_FILES['uploadedfile']['name']); 
$file_name = basename( $_FILES['uploadedfile']['name']);

if (substr( $file_name, strlen($file_name) - 3 , 3) == 'enc'){
	if(move_uploaded_file($_FILES['uploadedfile']['tmp_name'], $target_path)) {
	
	
	// Set the Environment Variable GS_LIB so GhostScript can find
	//    it fonts:
	putenv ("GS_LIB=/opt/ghostscript/share/ghostscript/7.07/fonts");
        // Adjust the UMASK so that others can read it.
        $old_umask = umask (022);

		//Run the processing of the uploaded file
		//....
		//...
		//system("R CMD BATCH /users/visitor/artes/PlotDiscusUnix.R");
		system("/usr/bin/R CMD BATCH --vanilla --slave /users/visitor/artes/public_html/PlotDiscusUnix.r");
		system("mv /users/visitor/artes/public_html/uploads/* /users/visitor/artes/public_html/uploadedFiles");
		//Generate an output file, copy its name, and send back to the index
	
		echo "The file ".  basename( $_FILES['uploadedfile']['name']). 
		" has been uploaded" . "<BR><BR>";
		
		// If there is a generated output, then show it here for download
		$filenameR0 = $file_name . ".pdf";
		$filenameR0 = str_replace(" ", "%20", $filenameR0);
		echo "Click here to download the <a target=_blank href=downloads/$filenameR0> Result</a>" . "<BR><BR>";
		//echo "Click here to download the <a target=_blank href=downloads/$filenameR0> Result</a>" . "<BR><BR>";
		//echo "Click here to download the result <a target=_blank href=downloads/result.png> Result</a>" . "<BR><BR>";
		
		echo "Click <a href=index.php>here</a> to return to the main page";
		$fielNameIpDate = $file_name . " " . $_SERVER['REMOTE_ADDR'] . " " . date(DATE_RFC822) . "\n";
		$fp = fopen("ipSystemTime.txt","a");
		fwrite($fp,$fielNameIpDate);
		fclose($fp); ;
	} else{
		echo "There was an error uploading the file, please try again!";
	}
}else{
	echo "No viruses please!";
}
?>
</html>
