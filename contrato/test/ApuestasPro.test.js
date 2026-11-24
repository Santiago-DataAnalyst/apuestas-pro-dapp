const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ApuestasPro", function () {
  async function deployFixture() {
    const [admin, alice, bob] = await ethers.getSigners();
    const ApuestasPro = await ethers.getContractFactory("ApuestasPro");
    const contrato = await ApuestasPro.deploy();
    await contrato.waitForDeployment();
    return { contrato, admin, alice, bob };
  }

  it("asigna al desplegador como administrador", async function () {
    const { contrato, admin } = await deployFixture();
    expect(await contrato.admin()).to.equal(admin.address);
  });

  it("permite al admin crear un evento y restringe a usuarios no autorizados", async function () {
    const { contrato, alice } = await deployFixture();
    await contrato.crearPartido(1, "Real Madrid vs Barcelona");
    const partido = await contrato.partidos(1);
    expect(partido.nombre).to.equal("Real Madrid vs Barcelona");
    expect(partido.finalizado).to.equal(false);

    await expect(
      contrato.connect(alice).crearPartido(2, "Otro Partido")
    ).to.be.revertedWith("No autorizado");
  });

  it("registra apuestas pari-mutuel, resuelve el evento y reparte premios proporcionalmente", async function () {
    const { contrato, alice, bob } = await deployFixture();
    await contrato.crearPartido(10, "Final Copa");

    const betAlice = ethers.parseEther("2.0"); // Opcion 1 (ganadora)
    const betBob = ethers.parseEther("1.0");   // Opcion 2 (perdedora)

    await contrato.connect(alice).apostar(10, 1, { value: betAlice });
    await contrato.connect(bob).apostar(10, 2, { value: betBob });

    await contrato.resolver(10, 1);

    // Alice debe recibir sus 2 ETH + el pozo perdedor completo (1 ETH) = 3 ETH
    await expect(
      contrato.connect(alice).reclamarPremio(10)
    ).to.changeEtherBalances(
      [contrato, alice],
      [ethers.parseEther("-3.0"), ethers.parseEther("3.0")]
    );

    // Evita doble reclamo
    await expect(
      contrato.connect(alice).reclamarPremio(10)
    ).to.be.revertedWith("No ganaste nada");
  });
});
