const Favorite = require('../models/Favorite');

// @desc    Ajouter une annonce aux favoris
// @route   POST /api/favorites
const addFavorite = async (req, res) => {
    try {
        const { propertyId } = req.body;
        if (!propertyId) {
            return res.status(400).json({ message: 'L\'ID de la propriété est requis' });
        }

        const favorite = await Favorite.create({
            user: req.user?.id,
            property: propertyId
        });

        res.status(201).json(favorite);
    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({ message: 'Cette propriété est déjà dans vos favoris' });
        }
        res.status(500).json({ message: 'Erreur lors de l\'ajout aux favoris', error: error.message });
    }
};

// @desc    Lister toutes les annonces favorites de l’utilisateur connecté
// @route   GET /api/favorites
const getMyFavorites = async (req, res) => {
    try {
        const favorites = await Favorite.find({ user: req.user?.id })
            .populate({
                path: 'property',
                populate: { path: 'owner', select: 'name email' }
            });
        res.json(favorites);
    } catch (error) {
        res.status(500).json({ message: 'Erreur lors de la récupération des favoris', error: error.message });
    }
};

// @desc    Retirer une annonce des favoris
// @route   DELETE /api/favorites/:propertyId
const removeFavorite = async (req, res) => {
    try {
        const result = await Favorite.findOneAndDelete({
            user: req.user?.id,
            property: req.params.propertyId
        });

        if (!result) {
            return res.status(404).json({ message: 'Favori non trouvé' });
        }

        res.json({ message: 'Annonce retirée des favoris' });
    } catch (error) {
        res.status(500).json({ message: 'Erreur lors de la suppression des favoris', error: error.message });
    }
};

// @desc    Basculer l'état favori d'une annonce (ajouter/retirer)
// @route   POST /api/favorites/toggle
const toggleFavorite = async (req, res) => {
    try {
        const { propertyId } = req.body;
        if (!propertyId) {
            return res.status(400).json({ message: 'L\'ID de la propriété est requis' });
        }

        // Vérifier si le favori existe déjà
        const existingFavorite = await Favorite.findOne({
            user: req.user?.id,
            property: propertyId
        });

        if (existingFavorite) {
            // Retirer des favoris
            await Favorite.findOneAndDelete({
                user: req.user?.id,
                property: propertyId
            });
            res.json({ message: 'Annonce retirée des favoris', isFavorite: false });
        } else {
            // Ajouter aux favoris
            const favorite = await Favorite.create({
                user: req.user?.id,
                property: propertyId
            });
            res.json({ message: 'Annonce ajoutée aux favoris', isFavorite: true });
        }
    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({ message: 'Cette propriété est déjà dans vos favoris' });
        }
        res.status(500).json({ message: 'Erreur lors de la gestion des favoris', error: error.message });
    }
};

module.exports = {
    addFavorite,
    getMyFavorites,
    removeFavorite,
    toggleFavorite
};
