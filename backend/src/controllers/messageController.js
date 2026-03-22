const Message = require('../models/Message');

const sendMessage = async (req, res) => {
    try {
        const { receiverId, propertyId, content } = req.body;
        if (!receiverId || !content) {
            return res.status(400).json({ message: 'Le destinataire et le contenu sont requis' });
        }

        const message = await Message.create({
            sender: req.user?.id,
            receiver: receiverId,
            property: propertyId || undefined,
            content
        });

        // Populate sender and receiver so the mobile client gets full user objects
        const populated = await Message.findById(message._id)
            .populate('sender', 'name email photo')
            .populate('receiver', 'name email photo');

        res.status(201).json(populated);
    } catch (error) {
        res.status(500).json({ message: 'Erreur lors de l\'envoi du message', error: error.message });
    }
};

const getConversation = async (req, res) => {
    try {
        const userId = req.user?.id;
        const otherUserId = req.params.userId;

        const messages = await Message.find({
            $or: [
                { sender: userId, receiver: otherUserId },
                { sender: otherUserId, receiver: userId }
            ]
        })
            .sort({ createdAt: 1 })
            .populate('sender', 'name photo')
            .populate('receiver', 'name photo');

        res.json(messages);
    } catch (error) {
        res.status(500).json({ message: 'Erreur lors de la récupération de la conversation', error: error.message });
    }
};

const getConversationsList = async (req, res) => {
    try {
        const userId = req.user?.id;

        // Find distinct users we have chatted with
        const messages = await Message.find({
            $or: [{ sender: userId }, { receiver: userId }]
        })
            .populate('sender', 'name email photo')
            .populate('receiver', 'name email photo')
            .sort({ createdAt: -1 });

        // Group by conversation partner
        const conversationsMap = new Map();

        messages.forEach(msg => {
            const partner = msg.sender._id.toString() === userId.toString() ? msg.receiver : msg.sender;
            const partnerId = partner._id.toString();

            if (!conversationsMap.has(partnerId)) {
                conversationsMap.set(partnerId, {
                    partner,
                    lastMessage: msg,
                    unreadCount: (!msg.isRead && msg.receiver._id.toString() === userId.toString()) ? 1 : 0
                });
            } else if (!msg.isRead && msg.receiver._id.toString() === userId.toString()) {
                conversationsMap.get(partnerId).unreadCount++;
            }
        });

        res.json(Array.from(conversationsMap.values()));
    } catch (error) {
        res.status(500).json({ message: 'Erreur lors de la récupération de la liste des conversations', error: error.message });
    }
};

const deleteMessage = async (req, res) => {
    try {
        const message = await Message.findById(req.params.id);
        if (!message) {
            return res.status(404).json({ message: 'Message non trouvé' });
        }

        if (message.sender.toString() !== req.user?.id && message.receiver.toString() !== req.user?.id) {
            return res.status(403).json({ message: 'Non autorisé à supprimer ce message' });
        }

        await Message.deleteOne({ _id: message._id });
        res.json({ message: 'Message supprimé' });
    } catch (error) {
        res.status(500).json({ message: 'Erreur lors de la suppression du message', error: error.message });
    }
};

const getUnreadCount = async (req, res) => {
    try {
        const count = await Message.countDocuments({
            receiver: req.user?.id,
            isRead: false
        });
        res.json({ unreadCount: count });
    } catch (error) {
        res.status(500).json({ message: 'Erreur lors du comptage des messages non lus', error: error.message });
    }
};

const markAsRead = async (req, res) => {
    try {
        const { otherUserId } = req.body;
        await Message.updateMany(
            { sender: otherUserId, receiver: req.user?.id, isRead: false },
            { $set: { isRead: true } }
        );
        res.json({ message: 'Messages marqués comme lus' });
    } catch (error) {
        res.status(500).json({ message: 'Erreur lors du marquage des messages', error: error.message });
    }
};

module.exports = {
    sendMessage,
    getConversation,
    getConversationsList,
    deleteMessage,
    getUnreadCount,
    markAsRead
};
