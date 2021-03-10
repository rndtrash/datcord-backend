require("dotenv").config();
const config = require(process.env.CONFIG || "./config.json");
require("./src/server.js").run({
	server: {
		host: process.env.HOST || config.server.host,
		port: process.env.PORT || config.server.port
	},
	db: {
		dataURI: process.env.DB_DATA_URI || config.db.dataURI,
		tokensURI: process.env.DB_TOKENS_URI || config.db.tokensURI
	}
});
