const http = require("http");
const service = require("restana")();

const v1 = require("./v1");

module.exports.run = (params) => {
	// Middleware
	service.use(require("response-time")());

	// API
	service.use("/v1", v1);

	http
		.createServer(service)
		.listen(params.server.port || 8579, params.server.host || "0.0.0.0", function () {
			console.log("running");
		});
};
