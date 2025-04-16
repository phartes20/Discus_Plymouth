// edited for playing PHA


//Wait for the document to laod
$(function(){

	//Default settings
	settings = {};
	settings['timeout'] = 10000;
	settings['pos'] = 0.1;      // PHA edit
	settings['neg'] = 0.3;      // PHA edit
	settings['max'] = 100;

	fileExtension = "jpeg";

	uploadURL = "http://web.cs.dal.ca/~artes/discusanalyze/uploader.php";

	currentImage = 0;
	preloadImages = 3;

	//Read any parameters from the URL
	parameters = window.location.search.substring(1).split("&");
	for (var i = 0; i < parameters.length; i++) {
		parameter = parameters[i].split("=");
		settings[parameter[0]] = parseInt(parameter[1]);
	};

	
	all = [];                  // Contains all images, displayed (and pre-loaded) images are chopped off
  PHADisplayedImages = [];   // Introduced to keep tap of all displayed images (FIX)
  
	//Generate links to positive images
	pos = [];	//Contains only "abnormal" images
	for (var number = 0; number < 20; number++){
		image = {status: "pos", imgname: "g ("+number+")." + fileExtension};
		pos.push(image);
		all.push(image); 
	}

	//Generate links to negative images
	neg = [];	//Contains only "normal" images
	for (var number = 0; number < 80; number++){
		image = {status: "neg", imgname: "c ("+number+")." + fileExtension};
		neg.push(image);
		all.push(image);
	}
  
	//Add repetition of images
	addRepetition(pos,"pos");
	addRepetition(neg,"neg");

	total = Math.floor(all.length * (settings['max'] / 100));
	progress = 1;
	$('#total').text(total);

	$('.progress-bar').css('width', (progress / total * 100) + "%");
	
	for (var i = 0; i < preloadImages; i++){     // pre-load a given number of images (3)
		generateRandomImage();                    
		image.hide();
		currentImage++;
	}

	currentImage = 0;    // clarify this
  
	image = $("#image" + currentImage);
	image.show();     

	content = settings['timeout'] + " " + settings['neg'] + " " + settings['pos'] + " 1";
	appendResponse(content);

  content = "name\tdate\ttime\tn\tstatus\timgname\tresponse\tlatency";
	appendResponse(content);

	started = false;

	$(window).keyup(function(event){
		if(started)
			switch(event.which){
				case 13: if (val) next(); break;
				case 49: chooseResponse(1); break;
				case 50: chooseResponse(2); break;
				case 51: chooseResponse(3); break;
				case 52: chooseResponse(4); break;
				case 53: chooseResponse(5); break;
				default: break;
			}
	});

	//Wait for changes in the name field
	$("#name").keyup(startOnOff);
	$("#name").change(startOnOff);

	function startOnOff(){
		//Store the name
		name = $(this).val();

		//Check for non-empty name
		if (name !== "")
			$("#start").removeAttr("disabled");				    //  Enable start button
		else $("#start").attr("disabled","disabled");		//  Disable start button
	}

	//Wait for click on start
	$('#start').click(function(){
		//Remove the intro
		$("#intro").remove();

		//Make the content visible
		$("#content").show();

		start = new Date().getTime();
		timer = setInterval(checkLatency, 1000);

		started = true;
	});

	//Wait for click on a radio button
	$('.response').change(function(){
		chooseResponse($(this).val());
	});

	function chooseResponse(res){
		//Store the response
		val = res;

		$('.response[value=' + val + ']').click();

		//Hide the image as soon as we have a response
		image.hide();

		//Calculate the latency
		end = new Date().getTime();
		latency = end - start;

		//Stop the timer
		clearInterval(timer);

		//Enable the next button
		$("#next").removeAttr('disabled');
	}

	//Wait for click on next
	$('#next').click(next);

	function next(){
		//Save the response
		saveResponse();

		//Update progress
		progress ++;
		$('#progress').text(progress);
		$('.progress-bar').css('width', (progress / total * 100) + "%");

		//Generate a random image if any left
		if(progress <= total){
			generateRandomImage();
      
			currentImage = (currentImage + 1) % preloadImages;      // I don't get this!! PHA
      
			image = $("#image" + currentImage);    
		
      image.show();
			start = new Date().getTime();
			timer = setInterval(checkLatency, 1000);

			$("#next").attr("disabled","disabled");
			$('.response').removeAttr('checked');
		}
		//Otherwise remove the content and display the finish screen
		else {
			$('#content').remove();
			$('#finish').show();
			upload();
		}
    
		delete val;
	}

	function upload(){
		form = $('#responses');
		form.attr('action', uploadURL);
		form.submit();
	}

	function generateRandomImage(){           //Method to generate a random picture
		if (all.length > 0){
			image = $("#image" + currentImage);   //Find the image on the page
    
			index = Math.floor(Math.random() * all.length);      		//Choose a random image from the unused images
			randomImage = all[index];  		     // Set the picture to the random picture
      
      // PHA:   push randomImage onto the "displayedImages" stack, so that I can get the names/status     
      PHADisplayedImages.push (randomImage)   
      
			status = randomImage.status;       
			imgname = randomImage.imgname;
			image.attr('src', "images/"+ status + "/" + imgname);
			all.splice(index,1);	  		//Remove the used image
		}
	}

	//Check latency to remove image if necessary
	function checkLatency(){
		end = new Date().getTime();
		latency = end - start;
		if (latency >= settings['timeout']){
			image.hide();
			clearInterval(timer);
		}
	}

	//Saves the response
	function saveResponse(){         // here be dragons...
		date = new Date();

		//Fix hours to display based on AM/PM clock
		hours = date.getHours();
		if (hours >= 12){
			hours = hours - 12;
			suffix = "PM";
		}
		else suffix = "AM";

		if (hours === 0)
			hours = 12;

		//Format time
		time = hours + ":" + date.getMinutes() + ":" + date.getSeconds() + " " + suffix;

		//Format date
		date = date.getDate() + "/" + (date.getMonth() + 1) + "/" + date.getFullYear();

		
    // PHA edit:   get the name of the last displayed image here.
    
    status = PHADisplayedImages[progress-1].status;
    imgname = PHADisplayedImages[progress-1].imgname;
    
    //Change extension of jpeg to ccc
		imgname = imgname.replace(fileExtension,'ccc');

		//Put it with the rest of the responses
		response = name + "\t";
		response += date + "\t";
		response += time + "\t";
		response += progress + "\t";
		response += status + "\t";
		response += imgname + "\t";
		response += val + "\t";
		response += latency;
		appendResponse(response); 
	}

	function appendResponse(response){
		$('#responses').append('<input type="text" name="responses[]" value="' + response + '"/>');
	}

	//Duplicate images based on the settings
	function addRepetition(array, name){
		originalLength = array.length * settings[name];
		//Add repetition of the "normal" images
		for (var i = 0; i < originalLength; i++) {
			//Choose a random image from "normal" images
			index = Math.floor(Math.random() * array.length);

			//Add it the images to display
			all.push(array[index]);

			//Remove image so it cannot be selected again
			array.splice(index,1);
		};
	}
});
