// TODO  Update sw cache as new poems are added after installation

const addResourcesToCache = async () => {
	resources = [
		"/index.html",
		"/stil.css",
		"/gruppedata.xml",
		"/gruppebilde.jpg",
		"/indexjs.html",
		"/indexScript.js",
		"/indexjsStil.css",
		"http://localhost:8180/"
	];
	
	await fetch("http://localhost:8180/")
		.then(reply => reply.text())
		.then(xmlString => {
			var poemids = [];
			let temp = xmlString.split("<diktID>");
			for (i = 1; i < temp.length; i++)
				poemids.push(temp[i].split("</diktID>")[0]);

			for (i = 0; i < poemids.length; i++)
				resources.push("http://localhost:8180/" + poemids[i]);
		});
	console.log(resources);
	
	const cache = await caches.open("swcache");
	return cache.addAll(resources); 
};

const newFirst = async (request) => {
	try {
		const serverResponse = await fetch(request);
		if (!serverResponse.ok)
			throw new Error("Error fetching from server.");
		return serverResponse;
	} catch {
		const cacheResponse = await caches.match(request);
		return cacheResponse;
	}
};

self.addEventListener("install", (event) => {
	event.waitUntil(addResourcesToCache());
});

self.addEventListener("fetch", (event) => {
	console.log("Service worker intercepted a fetch");
	event.respondWith(newFirst(event.request));
});
