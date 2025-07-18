// backend/internal/services/hub.go
package services

import (
	"log"
	"sync"

	"github.com/gorilla/websocket"
)

type Hub struct {
	clients     map[string]map[*websocket.Conn]bool
	broadcastCh chan ActivityMessage
	mu          sync.RWMutex
}

type ActivityMessage struct {
	RecipientIDs []string    // Who should receive this update
	Data         interface{} // Any JSON-serializable payload
}

var ActivityHub = NewHub()

func NewHub() *Hub {
	h := &Hub{
		clients:     make(map[string]map[*websocket.Conn]bool),
		broadcastCh: make(chan ActivityMessage, 100),
	}
	go h.run()
	return h
}

func (h *Hub) Register(userID string, conn *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.clients[userID] == nil {
		h.clients[userID] = make(map[*websocket.Conn]bool)
	}
	h.clients[userID][conn] = true
}

func (h *Hub) Unregister(userID string, conn *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	delete(h.clients[userID], conn)
	if len(h.clients[userID]) == 0 {
		delete(h.clients, userID)
	}
}

func (h *Hub) Broadcast(msg ActivityMessage) {
	h.broadcastCh <- msg
}

func (h *Hub) run() {
	for msg := range h.broadcastCh {
		h.mu.RLock()
		for _, uid := range msg.RecipientIDs {
			for conn := range h.clients[uid] {
				log.Printf("[Hub] Sending message to %v: %+v", uid, msg.Data)
				err := conn.WriteJSON(msg.Data)
				if err != nil {
					log.Printf("[Hub] ERROR writing to %v: %v", uid, err)
				}
			}
		}
		h.mu.RUnlock()
	}
}
