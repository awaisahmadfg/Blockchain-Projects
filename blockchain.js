const express = require('express');
const router = express.Router();
const { verifyRoles, checkAuthentication } = require('../middlewares');
const { COMMON } = require('../consts');
const blockchainController = require('../controllers/blockchainController');

router.get('/ideaCoinPrice', blockchainController.getIdeaCoinPrice);

router.use(checkAuthentication);

router.post(
  '/sendEthereum',
  verifyRoles([COMMON.ADMINS, COMMON.STANDARD_USER]),
  blockchainController.sendEthereum,
);

router.post(
  '/sendRoyaltyCoin',
  verifyRoles([COMMON.ADMINS, COMMON.STANDARD_USER]),
  blockchainController.sendRoyaltyCoin,
);

router.post(
  '/approveIdeaCoin',
  verifyRoles([COMMON.ADMINS, COMMON.STANDARD_USER]),
  blockchainController.approveIdeaCoin,
);

module.exports = router;
