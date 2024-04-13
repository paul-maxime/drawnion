import express from "express";
import http from "http";
import { WebSocketServer } from "ws";

import * as Game from "./game.mjs";

const app = express();
const httpServer = http.createServer(app);
const socketServer = new WebSocketServer({ server: httpServer });

socketServer.on("connection", (player) => {
  Game.onConnected(player);

  player.on("message", (raw) => {
    try {
      const message = JSON.parse(raw);
      if (!message) throw new Error("Invalid message");
      Game.onMessage(player, message);
    } catch (e) {
      console.error(e);
      player.close();
    }
  });

  player.on("close", () => {
    Game.onDisconnected(player);
  });
});

const PORT = process.env.PORT || 8080;
httpServer.listen(PORT, () => console.log(`Listening on port ${PORT}`));

Game.tick();
