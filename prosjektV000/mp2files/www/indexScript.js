var loginBoxLoggedIn = 	"<p>You are logged in</p><br>" +
			"<button onclick=\"logOut()\" type=\"button\">log out</button><br><br>" +
			"<button onclick=\"addPoem()\" type=\"button\">submit new poem</button><br><br>" +
			"<button onclick=\"deleteAllPoems()\" type=\"button\">delete all poems</button>";

var loginBoxLoggedOut =	"<p>You are not logged in</p>" +
	                "<label for=\"inUsername\">Username:</label><br>" +
	                "<input type=\"text\" id=\"inUsername\" name=\"inUsername\">" +
	                "<br><br>" +
	                "<label for=\"inPassword\">Password:</label><br>" +
	                "<input type=\"text\" id=\"inPassword\" name=\"inPassword\"><br>" +
	                "<button onclick=\"logIn()\" type=\"button\">Log in</button>";

var loggedIn = false;

function pageInit() {
	if (getSessionID() != "") {
		document.getElementById("loginBox").innerHTML = loginBoxLoggedIn;
		loggedIn = true;
	} else {
		document.getElementById("loginBox").innerHTML = loginBoxLoggedOut;
		loggedIn = false;
	}

	listPoems();
	registerServiceWorker();
}

function getSessionID() {
	let cookieField = "ssid=";
	let allCookies = decodeURIComponent(document.cookie).split(';');
	for (i = 0; i < allCookies.length; i++) {
		let cookie = allCookies[i];
		while (cookie.charAt(0) == ' ')
			cookie = cookie.substring(1);
		if (cookie.indexOf(cookieField) == 0)
			return cookie.substring(cookieField.length, cookie.length);
	}
	
	return "";
}

function logIn() {
	let email = document.getElementById("inUsername").value;
	let password = document.getElementById("inPassword").value;
	let xmlbody = "<?xml version=\"1.0\"?><!DOCTYPE DiktDB SYSTEM \"http://localhost/userLogin.dtd\"><Bruker><epost>" + email + "</epost><passord>" + password + "</passord></Bruker>";
	fetch("http://localhost:8180/login", {method: "POST", body: xmlbody, credentials: "include"})
		.then(reply => reply.text())
		.then(response => {
			if (response.includes("SUCCESS")) {			
				document.getElementById("loginBox").innerHTML = loginBoxLoggedIn;
				loggedIn = true;
				listPoems();
			} else {
				alert("Login failed");
			}
		});
}

function logOut() {
	fetch("http://localhost:8180/logout", {method: "DELETE", credentials: "include"})
		.then(reply => reply.text())
		.then(response => {
			document.getElementById("loginBox").innerHTML = loginBoxLoggedOut;
			loggedIn = false;
			listPoems();
		});
}

function addPoem() {
	document.getElementById("reply").innerHTML = "<textarea id=\"inNewPoem\" rows=\"10\" cols=\"50\"></textarea><br><button onclick=\"submitNewPoem()\" type=\"button\">submit</button>";
}

function submitNewPoem() {
	let xmlbody = "<?xml version=\"1.0\"?><!DOCTYPE DiktDB SYSTEM \"http://localhost/poemSubmission.dtd\"><Dikt><dikt>" + document.getElementById("inNewPoem").value + "</dikt></Dikt>";
	fetch("http://localhost:8180/", {method: "POST", body: xmlbody, credentials: "include"})
		.then(reply => reply.text())
		.then(response => {
			if (response.includes("SUCCESS")) {
				listPoems();
			} else {
				alert("Error submitting poem");
			}
		});
}

function viewPoem(id) {
	fetch("http://localhost:8180/" + id)
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let email = xmlDoc.getElementsByTagName("epost")[0].childNodes[0].nodeValue;
			let poem = xmlDoc.getElementsByTagName("dikt")[0].childNodes[0].nodeValue;
			document.getElementById("reply").innerHTML = "<h2>" + email + "</h2><p>" + poem + "</p>";
		});
}

function editPoem(id) {
	fetch("http://localhost:8180/" + id)
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let poem = xmlDoc.getElementsByTagName("dikt")[0].childNodes[0].nodeValue;
			document.getElementById("reply").innerHTML = "<h2>Editing poem</h2><textarea id=\"inEditedPoem\" rows=\"10\" cols=\"50\">" + poem + "</textarea><br><button onclick=\"submitEditedPoem(" + id + ")\" type=\"button\">submit</button>";
		});
}

function submitEditedPoem(id) {
	let xmlbody = "<?xml version=\"1.0\"?><!DOCTYPE DiktDB SYSTEM \"http://localhost/poemSubmission.dtd\"><Dikt><dikt>" + document.getElementById("inEditedPoem").value + "</dikt></Dikt>";
	fetch("http://localhost:8180/" + id, {method: "PUT", body: xmlbody, credentials: "include"})
		.then(reply => reply.text())
		.then(response => {
			if (response.includes("SUCCESS")) {
				listPoems();
			} else {
				alert("Error editing poem");
			}
		});
}

function deletePoem(id) {
	fetch("http://localhost:8180/" + id)
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let poem = xmlDoc.getElementsByTagName("dikt")[0].childNodes[0].nodeValue;
			document.getElementById("reply").innerHTML = "<h2>Are you sure you want to delete the poem?</h2><p>" + poem + "</p><br><button onclick=\"confirmPoemDeletion(" + id + ")\" type=\"button\">delete</button>";
		});
}

function confirmPoemDeletion(id) {
	fetch("http://localhost:8180/" + id, {method: "DELETE", credentials: "include"})
		.then(listPoems());
}

function deleteAllPoems() {
	document.getElementById("reply").innerHTML = "<h2>Are you sure you want to delete all of your poems?</h2><br><button onclick=\"confirmDeleteAllPoems()\" type=\"button\">delete all</button>";
}

function confirmDeleteAllPoems() {
	fetch("http://localhost:8180/", {method: "DELETE", credentials: "include"}) 
		.then(listPoems());
}

function listPoems() {
	fetch("http://localhost:8180/")
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let ids = xmlDoc.getElementsByTagName("diktID");
			let poems = xmlDoc.getElementsByTagName("dikt");
			let emails = xmlDoc.getElementsByTagName("epost");

			let text = "<table><tr><th>DiktID</th><th>Dikt</th><th>Epost</th></tr>";
			for (i = 0; i < ids.length; i++) {
				text += "<tr>";
				text += "<td>" + ids[i].childNodes[0].nodeValue + "</td>";
				text += "<td>" + poems[i].childNodes[0].nodeValue.substr(0, 20) + "...</td>";
				text += "<td>" + emails[i].childNodes[0].nodeValue + "</td>";
				text += "<td>";
				text += "<button onclick=\"viewPoem(" + ids[i].childNodes[0].nodeValue + ")\" type=\"button\">view</button>";
				text += "<button onclick=\"editPoem(" + ids[i].childNodes[0].nodeValue + ")\" type=\"button\" " + (loggedIn ? "" : "disabled") + ">edit</button>";
				text += "<button onclick=\"deletePoem(" + ids[i].childNodes[0].nodeValue + ")\" type=\"button\" " + (loggedIn ? "" : "disabled") + ">delete</button>";
				text += "</td>";
			}
			text += "</table>";
			document.getElementById("reply").innerHTML = text;
		});
}

const registerServiceWorker = async () => {
	if ("serviceWorker" in navigator) {
		try {
			navigator.serviceWorker.register("/serviceWorker.js");
		} catch (error) {
			console.error("Registration failed with" + error);
		}
	}
};
