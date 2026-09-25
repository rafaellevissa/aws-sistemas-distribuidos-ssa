const { Router } = require('express');
const usuariosController = require('../controllers/usuarios.controller');

const router = Router();

router.get('/', usuariosController.listar);
router.get('/:id', usuariosController.buscarPorId);
router.post('/', usuariosController.criar);
router.put('/:id', usuariosController.atualizar);
router.delete('/:id', usuariosController.remover);

module.exports = router;
