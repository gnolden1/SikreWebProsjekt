function logIn() {
	let username = document.getElementById("inUsername").value;
	let password = document.getElementById("inPassword").value;
	document.getElementById("reply").innerHTML = "<p>Username: " + username + "</p><br><p>Password: " + password + "</p>";
	document.cookie = "email=" + username;  //TODO remove
}

function logOut() {
}

function addPoem() {
}

function viewPoem(id) {
	fetch("/dikttest/dikt" + id + ".xml")
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let email = xmlDoc.getElementsByTagName("epost")[0].childNodes[0].nodeValue;
			let poem = xmlDoc.getElementsByTagName("dikt")[0].childNodes[0].nodeValue;
			document.getElementById("reply").innerHTML = "<h2>" + email + "</h2><p>" + poem + "</p>";
		});
}

function editPoem(id) {
	fetch("/dikttest/dikt" + id + ".xml")
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let poem = xmlDoc.getElementsByTagName("dikt")[0].childNodes[0].nodeValue;
			document.getElementById("reply").innerHTML = "<textarea id=\"inEditedPoem\" rows=\"10\" cols=\"50\">" + poem + "</textarea><br><button onclick=\"submitEditedPoem()\" type=\"button\">submit</button>";
		});
}

function submitEditedPoem() {
	listPoems();
}

function deletePoem(id) {
	alert("poem id: " + id);
}

function confirmPoemDeletion() {
	listPoems();
}

function deleteAllPoems() {
}

function listPoems() {
	fetch("/testdata.xml")
		.then(reply => reply.text())
		.then(xmlString => new window.DOMParser().parseFromString(xmlString, "text/xml"))
		.then(xmlDoc => {
			let ids = xmlDoc.getElementsByTagName("diktId");
			let poems = xmlDoc.getElementsByTagName("dikt");
			let emails = xmlDoc.getElementsByTagName("epost");
			// TODO Check if email matches, if not gray out buttons

			let text = "<table><tr><th>DiktID</th><th>Dikt</th><th>Epost</th></tr>";
			for (i = 0; i < ids.length; i++) {
				text += "<tr>";
				text += "<td>" + ids[i].childNodes[0].nodeValue + "</td>";
				text += "<td>" + poems[i].childNodes[0].nodeValue.substr(0, 20) + "...</td>";
				text += "<td>" + emails[i].childNodes[0].nodeValue + "</td>";
				text += "<td>";
				text += "<button onclick=\"viewPoem(" + ids[i].childNodes[0].nodeValue + ")\" type=\"button\">view</button>";
				text += "<button onclick=\"editPoem(" + ids[i].childNodes[0].nodeValue + ")\" type=\"button\">edit</button>";
				text += "<button onclick=\"deletePoem(" + ids[i].childNodes[0].nodeValue + ")\" type=\"button\">delete</button>";
				text += "</td>";
			}
			text += "</table>";
			text += "<p>" + document.cookie + "</p>";
			document.getElementById("reply").innerHTML = text;
		});
}
