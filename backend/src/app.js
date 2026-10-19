import express from "express";

export function createApp() {
  const app = express();

  app.get("/", (_request, response) => {
    response.json({
      service: "cps-on-call-roster-backend",
      status: "running"
    });
  });

  return app;
}
