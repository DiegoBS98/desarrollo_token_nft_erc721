//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../INTERFACES/IERC165.sol";
//El contrato ERC165 nos ayuda para saber si una direccion soporta un standard
abstract contract ERC165 is IERC165{
    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool){
        return interfaceId == type(IERC165).interfaceId;
    }
}