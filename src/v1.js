const sequential = require("0http/lib/router/sequential");

const v1router = sequential();

v1router.get("/ping", (req, res) => {
	res.send({
		msg: "Pong!",
	});
});

module.exports = v1router;
