//= require jquery
//= require jquery_ujs

$(document).ready(function(){
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