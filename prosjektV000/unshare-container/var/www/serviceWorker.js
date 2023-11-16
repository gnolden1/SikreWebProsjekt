const addResourcesToCache = async () => {
	resources = [
		"/index.html",
		"/stil.css",
		"/gruppedata.xml",
		"/gruppebilde.jpg",
		"/indexjs.html",
		"/indexScript.js",
		"/indexjsStil.css",
	//	"http://localhost:8080/diktdb/dikt/"
	];
	var poemids = [];
	await fetch("/testdata.xml")  // TODO change to correct fetch
		.then(reply => reply.text())
		.then(xmlString => {
			let temp = xmlString.split("<diktId>");
			for (i = 1; i < temp.length; i++)
				poemids.push(temp[i].split("</diktId>")[0]);
		});
	//for (i = 0; i < poemids.length; i++) 
	//	resources.push("http://localhost:8080/diktdb/dikt/" + poemids[i]);

	const cache = await caches.open("swcache");
	return cache.addAll(resources);  // await?
};

const cacheFirst = async (request) => {
	const responseFromCache = await caches.match(request);
	if (responseFromCache)
		return responseFromCache;

	return fetch(request);
};

self.addEventListener("install", (event) => {
	event.waitUntil(addResourcesToCache());
});

self.addEventListener("fetch", (event) => {
	event.respondWith(cacheFirst(event.request));
});
