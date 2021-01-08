require("dotenv").config();
require("./src/server.js").run({
	host: process.env.HOST,
	port: process.env.PORT,
	dbURI: process.env.DB_URI,
});
