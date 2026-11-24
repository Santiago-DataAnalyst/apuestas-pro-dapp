const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("ModuloApuestas", (m) => {
  const apuestas = m.contract("ApuestasPro"); 
  return { apuestas };
});