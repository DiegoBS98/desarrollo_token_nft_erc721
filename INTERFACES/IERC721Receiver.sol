//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//Comprueba si la address que recibe es compatible con el standard 721 para que, en caso de no serlo, no se pierda el token
//La wallet puede ser externa o de un contrato, por eso hay que verificar que pueda recibirlo
interface IERC721Receiver {
    function onERC721Receiver(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}
