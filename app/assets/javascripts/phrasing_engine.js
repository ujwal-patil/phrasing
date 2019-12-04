//= require jquery
//= require jquery_ujs
//= require jquery.remotipart

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
	var button = this,
			processBar = $('#live-process-bar');

	disableFilters(true);

	$.ajax({
	  url: this.dataset.path,
    type: "GET",
    success: showProcessBar,
    error: function(error){
	    disableFilters(false)
    }
	});

	function showProcessBar(){
		var message = $('#rq-message');	
		processBar.find('div[role=progressbar]').css('width', '0%')	
		var interval = setInterval(showStatus, 1000);

		function showStatus(){
			$.ajax({
	  	  url: '/phrasing/go_live_status',
		    type: "get",
		    success: function(response) {
		  	  // console.log("success", response);
					processBar.show();
					processBar.find('div[role=progressbar]').css('width', response.progress +'%')

	  	    if (response.in_progress == 'false'){
	  	    	clearInterval(interval);
	  	    	disableFilters(false);

		  			if (response.progress == 100) {
		  				showMessage('Requested Successfully, Please note Added Words: '+response.added_words+', Removed Words: '+response.removed_words, 'alert-success');
		  				timeoutProgress();
		  			}
		  	  }
		    },
		    error: function(error){
		    	disableFilters(false);
	  	    clearInterval(interval);
	  	    showProgressBarMessage('Fail to request, retry', 'c-red')
	  	    timeoutProgress();
		    }
			});
		}

		function timeoutProgress(){
			setTimeout(function() {
				processBar.hide();
				message.hide();
			}, 5000);
		}

		function showProgressBarMessage(messageText, klass){
			message.show();
			message.removeClass('c-red');
			message.removeClass('c-green');
			message.addClass(klass);
			message[0].innerText = messageText;
		}
	}

	function disableFilters(disable){
		var editables = $('.editable'),
			filterAnchors = $('.filters a.btn'),
			filterInputs = $('.filters input, .filters select');

		if (disable) {
			editables.prop('contenteditable', false);
			button.disabled = true;
			filterInputs.attr('disabled', true);
			filterAnchors.css("pointer-events", "none")
		}
		else{
			editables.prop('contenteditable', true);
			button.disabled = false;
			filterInputs.attr('disabled', false);
			filterAnchors.css("pointer-events", "all");
		}
	}
}

function showProcessBar(){
	var processBar = $('#live-process-bar');
	var interval = setInterval(getStatus, 1000);
	var cardInputs = $('#import-card input');

	cardInputs.prop('disabled', true);

	processBar.find('div[role=progressbar]').css('width', '0%')	
	
	function getStatus(){
		$.ajax({
	    url: '/phrasing/upload_status',
	    data: {locale: processBar.data('locale')},
	    type: "get",
	    success: function(response) {
	  	  // console.log("success", response);
				processBar.show();
				processBar.find('div[role=progressbar]').css('width', response.progress +'%')

  	    if (response.progress == '100'){
  	    	clearInterval(interval);
  	    	processBar.hide();
  	    	cardInputs.prop('disabled', false);
  	    	processBar.find('div[role=progressbar]').css('width', '0%');
  				showMessage('Successfully Uploaded with '+response.no_of_changes+' changes ', 'alert-success');
  	    }
	    },
	    error: function(error){
  	    // console.log("error", error)
  	    clearInterval(interval);
  	    processBar.hide();
  	   	cardInputs.prop('disabled', false);
  	    showMessage('Fail to upload', 'alert-danger')
	    }
		});
	}
}

function showMessage(messageText, klass){
	var messageBox = $('#progress-message');
	messageBox[0].innerText = messageText;
	messageBox.removeClass('alert-danger');
	messageBox.removeClass('alert-success');
	messageBox.addClass(klass)
	messageBox.show();
}

