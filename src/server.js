const http = require("http");
const service = require("restana")();

const v1 = require("./v1");

module.exports.run = (params) => {
	service.use(require("response-time")());
	service.use("/v1", v1);

	http
		.createServer(service)
		.listen(params.port || 8579, params.host || "0.0.0.0", function () {
			console.log("running");
		});
};
