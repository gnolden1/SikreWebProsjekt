function logIn() {
	let username = document.getElementById("inUsername").value;
	let password = document.getElementById("inPassword").value;
	document.getElementById("reply").innerHTML = "<p>Username: " + username + "</p><br><p>Password: " + password + "</p>";
}

function fetchList() {
	fetch("/")
		.then(reply => reply.text())
		.then(replyBody => document.getElementById("reply").innerHTML = replyBody);
}
