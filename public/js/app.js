
/*

	I'm not a javascript developer so I don't really have any concept of where values for the application state ought to go.
	I'm doing my best, and for now I'm going to keep some of these values in the global state.

*/

var buttonTitle = "Welcome";
var sendLogin = true;

var isArticlePublished = false;

function login() {
	var data = {
		username: $("input[name=login_email]").val(),
		password: $("input[name=login_password]").val(),
	};
	
	console.log("dataaaaaaaaaaaaaaaaa");
	
	var register = $("input[name=login_register]").attr("checked");
	$.ajax({
		
		type: "POST",
		url: sendLogin === true ? "/api/user/login" : "/api/user/create",
		contentType: 'application/json',
		data: JSON.stringify(data),
		success: function(r) {
			if (r.status == "OK") {
				document.cookie = 'auth=' + r.auth_token +
				'; expires=Thu, 1 Aug 2030 20:00:00 UTC; path=/';
				window.location.href = "/dashboard";
			} else {
				alert(r.error);
			}
		}
		
		
	});
	return false;
}

function logout() {
	document.cookie = encodeURIComponent("auth") + "=deleted; expires=" + new Date(0).toUTCString();
	window.location.replace("/");
}


function mainButton() {
	return $("input[name=do_login]");
}


function textChanged() {
	// var bodyArea = $("body_text_area");
	// var bodyText = bodyArea.val();
	// 
	// if (bodyText.length < 1)
	// return;
	
	this.cancelTimeout();
	this.timeoutID = window.setTimeout(function() {
		this.autosaveTimerFired();
	}, 1000);
	
}
function setIdea() {
	if (!isArticlePublished) {
		//return;
	}
	
	var postData = {
		"articleID" : articleID,
		"apisecret" : apiSecret,
		"state"		: "article_status_idea"
	};
	console.log("setting idea?");
	$.ajax({
		type: "POST",
		url: "/api/article/status/" + articleID,
		data: JSON.stringify(postData),
		success: function (response) {
			if (response.status == "OK") {
				console.log("OK!!");
				document.location.reload(true);
			} else {
				console.log(response);
				showError(response.error);
			}
		}
	});
	
}
function setPublished() {
	if (isArticlePublished) {
		return;
	}
	
	
	var postData = {
		"articleID" : articleID,
		"apisecret" : apiSecret,
		"state"		: "article_status_published"
	};
	console.log(JSON.stringify(postData));
	$.ajax({
		type: "post",
		url: "/api/article/status/" + articleID,
		data: JSON.stringify(postData),
		contentType: "application/json",
		success: function(response) {
			if (response.status == "OK") {
				console.log("article set to published!");
				document.location.reload(true);
			} else {
				console.log(response);
				showError(response.error);
				if (contains(response.error, "headline")) {
					var headerText = $("#editor_title");
					headerText.addClass("error_row");
					// TODO: finish me, error handling
					
				}
			}
		}
	});
	
}
function previewInNewTab() {
	var url = "/dashboard/articles/preview/" + articleID;
	window.open(url, "_blank");
}
function showFormattingHelp() {
	window.open("http://daringfireball.net/projects/markdown/basics", "_blank");
}
function confirmDelete() {}


function autosaveTimerFired() {
	console.log("AUTOSAVE!!");
	delete this.timeoutID;
	
	var bodyArea = $("#body_text_area");
	var headerText = $("#editor_title");
	var sourceText = $("#editor_source");
	
	var postData = {
		"source": sourceText.val(),
		"headline": headerText.val(),
		"body": bodyArea.val(),
		"apisecret": apiSecret,
		"articleID": articleID
	};
	
	
	var autosaveLabel = $("#autosave_label");
	var bodyText = bodyArea.val();
	
	var components = bodyText.split(/\s+/g);
	var numberOfWords;
	if (components[0] === "") {
		numberOfWords = 0;
	} else {
		numberOfWords = components.length;
	}
	var suffix = numberOfWords == 1? "" : "s";
	
	autosaveLabel.text("saving " + numberOfWords + " word" + suffix + "...");
	console.log("har");
	
	$.ajax({
		type: "POST",
		url: "/api/article/update/" + articleID,
		data: JSON.stringify(postData),
		success: function (response) {
			console.log(response);
			if (response.status == "OK") {
				autosaveLabel.text("saved " + numberOfWords + " word" + suffix);
			} else {
				autosaveLabel.text(response.error);
			}
		}
	});
	
}


function cancelTimeout() {
	if (typeof this.timeoutID == "number") {
		window.clearTimeout(this.timeoutID);
		delete this.timeoutID;
	}
}


$(document).ready(function() {
	
	// set up some of the initial app state


	mainButton().val(buttonTitle);
	this.cancelTimeout = function() {
		if (typeof this.timeoutID == "number") {
			window.clearTimeout(this.timeoutID);
			delete this.timeoutID;
		}
	};


	this.checkEmailExists = function(email) {
		if (email.length < 1)
			return;
		console.log("Will check for email " + email);
		var data = {
			username: $("input[name=login_email]").val(),
		};
		$.ajax({
			type: "GET",
			url: "/api/user/exists",
			data: data,
			success: function (response) {
				console.log(response);
				if (response.exists === true) {
					//alert("Yep!");
					console.log("yep!");
					$("input[name=do_login]").val("Log In");
					sendLogin = true;
				} else {
					//alert("Nope");
					console.log("nope");
					$("input[name=do_login]").val("Sign Up");
					sendLogin = false;
				}
			}
		});
		delete this.timeoutID;
	}

	var self = this;
	$("#login_email_input").keyup(function() {
		//console.log($(this).val());
		var email = $(this).val();

		self.cancelTimeout();


		self.timeoutID = window.setTimeout(function() {
			//console.log(email);
			self.checkEmailExists(email);
		}, 1000);
	})
	
	
	if (!isEditorPage()) {
		return;
	}
	
	
	var ideaButton = $("#idea_button");
	isArticlePublished = (ideaButton.attr("class").indexOf("button_chosen") != -1)? false : true;
	console.log(isArticlePublished.toString());
	
	
	// Set up key bindings for the editor:
	key("command+s, ctrl+s", function() {
		console.log("save keys?");
		autosaveTimerFired();
		return false;
	});
	
	key.filter = function(event) {
		var tagName = (event.target || event.srcElement).tagName;
		return (tagName != 'SELECT');
	}
	
});



// General functions

function isEditorPage() {
	var ideaButton = $("#idea_button");
	var publishedButton = $("#published_button");
	if (!ideaButton.length || !publishedButton.length) return false;
	
	return true;
}

function contains(string, search) {
	return (string.indexOf(search) != -1);
}


function showError(error) {
	var autosaveLabel = $("#autosave_label");
	autosaveLabel.text(error);
}
