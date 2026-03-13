const User = require('../models/User');
const jwt = require('jsonwebtoken');

const generateToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET || 'secret', {
        expiresIn: '7d',
    });
};

const registerUser = async (req, res) => {
    try {
        const { name, email, password, role, phone } = req.body;
        
        // Validate required fields
        if (!name || !email || !password || !phone) {
            return res.status(400).json({ 
                message: 'Tous les champs sont obligatoires (name, email, password, phone)' 
            });
        }

        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ message: 'Format email invalide' });
        }

        // Validate password length
        if (password.length < 6) {
            return res.status(400).json({ message: 'Le mot de passe doit avoir au moins 6 caractères' });
        }

        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'L\'utilisateur existe déjà' });
        }

        const user = await User.create({
            name,
            email,
            password,
            role: role || 'buyer',
            phone,
        });

        if (user) {
            res.status(201).json({
                _id: user._id || user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                phone: user.phone,
                photoUrl: user.photoUrl,
                isEmailVerified: user.isEmailVerified,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt,
                token: generateToken(user.id, user.role),
                message: 'Inscription réussie'
            });
        } else {
            res.status(400).json({ message: 'Données invalides' });
        }
    } catch (error) {
        console.error('REGISTER ERROR:', error);
        res.status(500).json({ message: error.message || 'Erreur serveur', error: error.message });
    }
};

const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;
        
        // Validate required fields
        if (!email || !password) {
            return res.status(400).json({ 
                message: 'Email et mot de passe sont obligatoires' 
            });
        }

        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ message: 'Format email invalide' });
        }

        const user = await User.findOne({ email });
        
        if (user && (await user.comparePassword(password))) {
            res.json({
                _id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                phone: user.phone,
                token: generateToken(user.id, user.role),
                message: 'Connexion réussie'
            });
        } else {
            res.status(401).json({ message: 'Email ou mot de passe incorrect' });
        }
    } catch (error) {
        console.error('LOGIN ERROR:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
};

const getUserProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password');
        if (user) {
            res.json(user);
        } else {
            res.status(404).json({ message: 'Utilisateur non trouvé' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
};

const updateUserProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        user.name = req.body.name || user.name;
        user.phone = req.body.phone || user.phone;
        
        if (req.body.newPassword) {
            // Verify old password if changing password
            if (req.body.oldPassword) {
                const isOldPasswordValid = await user.comparePassword(req.body.oldPassword);
                if (!isOldPasswordValid) {
                    return res.status(400).json({ message: 'Ancien mot de passe incorrect' });
                }
            }
            user.password = req.body.newPassword;
        }

        if (req.file) {
            user.photoUrl = `/uploads/${req.file.filename}`;
        }

        const updatedUser = await user.save();
        res.json({
            _id: updatedUser.id,
            name: updatedUser.name,
            email: updatedUser.email,
            role: updatedUser.role,
            phone: updatedUser.phone,
            photoUrl: updatedUser.photoUrl,
            token: generateToken(updatedUser.id, updatedUser.role)
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
};

const deleteUserProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        await User.deleteOne({ _id: user._id });
        res.json({ message: 'Compte utilisateur supprimé' });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
};

module.exports = {
    registerUser,
    loginUser,
    getUserProfile,
    updateUserProfile,
    deleteUserProfile
};
