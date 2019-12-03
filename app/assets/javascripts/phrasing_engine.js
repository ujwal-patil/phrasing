//= require jquery
//= require jquery_ujs
//= require turbolinks

$(document).ready(function(){
	$("#request-live").on('click', requestLive);

	$(".editable").on('focusout', function (event) {
		var element = $(this),
		  hiddenEle = $(this.dataset.textid);
		
		if (hiddenEle.val() != this.innerText) {
			hiddenEle.val(this.innerText);

		    $.ajax({
		  	    url: this.dataset.url,
			    type: "PUT",
			    data: $(this.closest('form')).serialize(),
			    success: function(response) {
			  	    console.log("success", response)
			   	    showCurrentStatus(element, 'success');
			    },
			    error: function(error){
			  	    console.log("error", error)
			   	    showCurrentStatus(element, 'danger');
			    }
			});
		}
	})
});

function showCurrentStatus(element, klass){
 	$('.editable').removeClass('success');
    $('.editable').removeClass('danger')
    element.addClass(klass);
}

function requestLive(){
	var button = this;
	var processBar = $('#live-process-bar');
	button.disabled = true;

  	$.ajax({
  	    url: this.dataset.path,
	    type: "GET",
	    success: function(response) {
	  	    console.log("success", response);
	  	    showProcessBar();
	    },
	    error: function(error){
	  	    console.log("error", error)
	  	    button.disabled = false;
	  	    processBar.hide();
	   	    
	    }
	});

	function showProcessBar(){
		var message = $('#rq-message');	
		processBar.find('div[role=progressbar]').css('width', '0%')	
		var interval = setInterval(getStatus, 1000);

		function getStatus(){
			$.ajax({
		  	    url: '/phrasing/go_live_status',
			    type: "get",
			    success: function(response) {
			  	    console.log("success", response);
					processBar.show();

					processBar.find('div[role=progressbar]').css('width', response.progress +'%')
			  	    if (response.in_progress == 'false'){
			  	    	clearInterval(interval);
			  	    	button.disabled = false;
			  			if (response.progress == 100) {
			  				showMessage('Successfully Requested.', 'c-green');
			  			}
			  	    }
			    },
			    error: function(error){
			  	    console.log("error", error)
			  	    clearInterval(interval);
			  	    button.disabled = false;
			  	    processBar.hide();
			  	    showMessage('Requested Failed', 'c-red')
			    }
			});
		}

		function showMessage(messageText, klass){
			message.show();
			message.removeClass('c-red');
			message.removeClass('c-green');
			message.addClass(klass);
			message[0].innerText = messageText;

			setTimeout(function() {
				processBar.hide();
				message.hide();
			}, 5000);
		}
	}
}

