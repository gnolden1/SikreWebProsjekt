var loggedIn = false;

function pageInit() {
	if (isLoggedIn()) {
		document.getElementById("loginBox").innerHTML = "<p>You are logged in</p><br><button onclick=\"logOut()\" type=\"button\">log out</button>";
		loggedIn = true;
	}
	listPoems();
	//registerServiceWorker();
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

function isLoggedIn() {
	return (getSessionID() != "");
}

function logIn() {
	let email = document.getElementById("inUsername").value;
	let password = document.getElementById("inPassword").value;
	let xmlbody = "";  // TODO Se hvordan body her skal være med hensyn til database
	fetch("/diktdb/login", {  // TODO Change to correct fetch
		method: "POST",
		headers: {
			"Content-Type": "text/xml",
		},
		body: xmlbody,
	});
	// TODO Give response based on whether successful or not
	// TODO if successful then also add email cookie
	document.getElementById("loginBox").innerHTML = "<p>You are logged in</p><br><button onclick=\"logOut()\" type=\"button\">log out</button>";
	loggedIn = true;
	listPoems();
}

function logOut() {
	fetch("/diktdb/logut", {method: "DELETE"});
	document.cookie = "ssid=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
	let text = "<p>You are not logged in</p>" +
		"<label for=\"inUsername\">Username:</label><br>" +
		"<input type=\"text\" id=\"inUsername\" name=\"inUsername\">" +
		"<br><br>" +
		"<label for=\"inPassword\">Password:</label><br>" +
		"<input type=\"text\" id=\"inPassword\" name=\"inPassword\"><br>" +
		"<button onclick=\"logIn()\" type=\"button\">Log in</button>";
	document.getElementById("loginBox").innerHTML = text;
	loggedIn = false;
	listPoems();
}

function addPoem() {
	document.getElementById("reply").innerHTML = "<textarea id=\"inNewPoem\" rows=\"10\" cols=\"50\">" + poem + "</textarea><br><button onclick=\"submitNewPoem(" + id + ")\" type=\"button\">submit</button>";
}

function submitNewPoem() {
	let xmlbody = "<dikt>" + document.getElementById("inNewPoem").value + "</dikt>";
	fetch("/diktdb/dikt/", {  // TODO Change to correct fetch
		method: "POST",
		headers: {
			"Content-Type": "text/xml",
		},
		body: xmlbody,
	});
	// TODO Give response based on whether successful or not
}

function viewPoem(id) {
	fetch("/dikttest/dikt" + id + ".xml")  // TODO Change to correct fetch
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let email = xmlDoc.getElementsByTagName("epost")[0].childNodes[0].nodeValue;
			let poem = xmlDoc.getElementsByTagName("dikt")[0].childNodes[0].nodeValue;
			document.getElementById("reply").innerHTML = "<h2>" + email + "</h2><p>" + poem + "</p>";
		});
}

function editPoem(id) {
	fetch("/dikttest/dikt" + id + ".xml")  // TODO Change to correct fetch
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let poem = xmlDoc.getElementsByTagName("dikt")[0].childNodes[0].nodeValue;
			document.getElementById("reply").innerHTML = "<h2>Editing poem</h2><textarea id=\"inEditedPoem\" rows=\"10\" cols=\"50\">" + poem + "</textarea><br><button onclick=\"submitEditedPoem(" + id + ")\" type=\"button\">submit</button>";
		});
}

function submitEditedPoem(id) {
	let xmlbody = "<dikt>" + document.getElementById("inEditedPoem").value + "</dikt>";
	fetch("/diktdb/dikt/" + id, {  // TODO Change to correct fetch
		method: "PUT",
		headers: {
			"Content-Type": "text/xml",
		},
		body: xmlbody,
	});
	// TODO Give response based on whether successful or not
}

function deletePoem(id) {
	fetch("/dikttest/dikt" + id + ".xml")  // TODO Change to correct fetch
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let poem = xmlDoc.getElementsByTagName("dikt")[0].childNodes[0].nodeValue;
			document.getElementById("reply").innerHTML = "<h2>Are you sure you want to delete the poem?</h2><p>" + poem + "</p><br><button onclick=\"confirmPoemDeletion(" + id + ")\" type=\"button\">delete</button>";
		});
}

function confirmPoemDeletion(id) {
	fetch("/diktdb/dikt/" + id, {method: "DELETE"});  // TODO change to correct fetch
	// TODO Give response based on whether successful or not
}

function deleteAllPoems() {
	document.getElementById("reply").innerHTML = "<h2>Are you sure you want to delete all of your poems?</h2><br><button onclick=\"confirmDeleteAllPoems()\" type=\"button\">delete all</button>";
}

function confirmDeleteAllPoems() {
	fetch("/diktdb/dikt/", {method: "DELETE"});  // TODO change to correct fetch
	// TODO Give response based on whether successful or not
}

function listPoems() {
	fetch("/testdata.xml")  // TODO Change to correct fetch
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let ids = xmlDoc.getElementsByTagName("diktId");
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
