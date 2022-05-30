//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
//Interfaz del standar erc721 que tendrán los token que minteemos
interface IERC721 is IERC165{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);//Saber la cantidad de balance que hay en una address
    function ownerOf(uint256 tokenId) external view returns (address owner); //Saber el dueño de un token
    function safeTransferFrom(address from, address to, uint256 tokenId) external ; //Envio seguro de nuestro nft
    function transferFrom(address from , address to, uint256 tokenId) external; //Funcion mas a bajo nivel que nos permite la transferencia de un determinado token de una direccion a otra
    function approve(address to, uint256 tokenId) external; //Dar permiso a una direccion de manejar un token que no es suyo
    function getApproved(uint256 tokenId) external view returns (address operator); //Saber quien tiene permiso para manejar ese token 
    function setApprovalForAll(address operator, bool _approved) external; //Permite a una direccion manejar todos los tokens  de la address owner a otra addres
    function isApprovedForAll(address owner, address operator) external view returns(bool); //Saber si una direccion tiene permiso para manejar tokens del owner
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external; //Envio seguro de nuestro nft con el parametro data, que tendra los datos adicionales del nft que queramos enviar
}