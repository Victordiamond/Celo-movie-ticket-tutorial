---
title: Building a Movie Ticketing Smart Contract on the Celo Blockchain
description: This tutorial will teach you how to create a movie ticket on celo blockchain for cinemas booking
authors:
  - name: Ubah Victor
---

# TABLE OF CONTENT
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [SmartContract](#smartcontract)
  - [How The Contract Works](#how-the-contract-works)
    - [Contract Structure and Imports](#contract-structure-and-imports)
    - [Define Modifiers](#define-modifiers)
    - [Add Movie](#add-movie)
    - [Get Movie Ticket Details](#get-movie-ticket-details)
    - [Add Tickets](#add-tickets)
    - [Change Ticket Sale Status](#change-ticket-sale-status)
    - [Remove Ticket](#remove-ticket)
    - [Block Tickets](#block-tickets)
    - [Buy Movie Tickets](#buy-movie-tickets)
    - [Refund Tickets](#refund-tickets)
    - [Additional Helper Functions](#additional-helper-functions)
  - [Deployment](#deployment)
  - [Conclusion](#conclusion)
  - [Next Steps](#next-steps)

## Introduction
In this DIY course, we will guide you through the process of building a movie ticketing smart contract using Solidity on the Celo blockchain. The smart contract will allow users to purchase movie tickets, manage ticket availability, and track revenue.

This course is designed for those with a basic understanding of blockchain technology and programming in Solidity. By the end of this course, you will have practical experience in developing a smart contract for movie ticketing, and you will understand the underlying concepts of blockchain-based systems.

## Prerequisites

Before getting started, ensure you have the following:

1. Familiarity with Solidity programming language and smart contract development.
2. A local development environment, such as Remix or Truffle, for writing and testing smart contracts.
3. A Celo account with some Celo dollars (cUSD) or Celo native assets (CELO) for paying transaction fees on the network.
4. A Celo network node endpoint to connect to, either a remote node or a local node running on your machine.
5. A wallet application, such as Valora or Ledger Live, for interacting with the Celo network and signing transactions.
6. The necessary contract deployment scripts or tooling, such as Hardhat or Brownie, for compiling and deploying smart contracts to the Celo network.
7. A clear understanding of gas limits and costs, as well as contract size limitations on the Celo network.
8. A plan for testing and verifying the functionality of the smart contract on the Celo network before deploying it to a production environment.

## SmartContract

Let's begin writing our smart contract in Remix IDE

This is the complete code.

```solidity
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**

@title MovieTicketSale
@dev This contract implements the functionality for buying and selling movie tickets using a cUSD token.
The contract is Ownable, meaning only the contract owner can perform certain administrative functions.
The contract uses the IERC20 interface to interact with the cUSD token.
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Movietickets is Ownable {
    /**    
    @dev Function to add a new movie ticket to the marketplace.
    @param _name The name of the movie.
    @param _image The URL of the movie poster image.
    @param _filmIndustry The name of the film industry producing the movie.
    @param _genre The genre of the movie.
    @param _description A brief description of the movie.
    @param _price The price of one movie ticket in cUSD.
    @param _ticketsAvailable The number of tickets that are available for purchase.
    */
    struct Movieticket {
        address payable admin;
        string name;
        string image;
        string filmIndustry;
        string genre;
        string description;
        uint price;
        uint sold;
        uint ticketsAvailable;
        bool forSale;
    }


    /**
    * @dev The number of movies currently available.
    */
    uint internal moviesLength = 0;

    /**
    * @dev The address of the cUSD token contract.
    */
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    
    /**
    @dev A mapping of Movieticket structs, representing all the movies that can be purchased with the ticketing system.
    */
    mapping (uint => Movieticket) internal movies;
    /**
    @dev Mapping to store the number of movie tickets purchased by each user for each movie index.
    */
    mapping (address => mapping (uint => uint)) internal userTickets;
    
    /**
    @dev totalRevenue is a uint variable to keep track of the total revenue generated from ticket sales.
    */
    uint internal totalRevenue = 0;

    /**
    * @dev Emitted when a user purchases movie tickets.
    * @param buyer The address of the buyer.
    * @param movieIndex The index of the movie for which tickets were purchased.
    * @param ticketCount The number of tickets purchased.
    */
    event TicketPurchase(address indexed buyer, uint indexed movieIndex, uint ticketCount);
    /**
    @dev Emitted when a user is refunded for movie tickets.
    @param buyer The address of the user who is refunded for the tickets.
    @param movieIndex The index of the movie for which the tickets were refunded.
    @param ticketCount The number of tickets refunded.
    */
    event TicketRefund(address indexed buyer, uint indexed movieIndex, uint ticketCount);

    /**
    * @dev Modifier to check ticket availability
    * @param _index index of the movie ticket in the movies mapping
    * @param _tickets number of tickets to buy
    */
    modifier isTicketAvailable(uint _index, uint _tickets) {
        require(movies[_index].ticketsAvailable >= _tickets, "Tickets not sufficient");
        _;
    }

    /**
    * @dev Modifier to check if the ticket is for sale
    * @param _index index of the movie ticket in the movies mapping
    */
    modifier isTicketForSale(uint _index) {
        require(movies[_index].forSale == true, "Ticket is not for sale");
        _;
    }

    /**
    @dev Modifier that checks if the caller is the admin of the movie ticket.
    */
    modifier isAdmin(uint _index) {
        require(msg.sender == movies[_index].admin, "Only admin");
        _;
    }


    
    /**
    @dev Allows owner to add a new movie to the contract.
    @param _name Name of the movie.
    @param _image IPFS hash of the movie poster image.
    @param _filmIndustry Film industry to which the movie belongs.
    @param _genre Genre of the movie.
    @param _description Description of the movie.
    @param _price Price of one movie ticket.
    @param _ticketsAvailable Total number of tickets available for the movie.
    Requirements:
    Only contract owner can call this function.
    Name, Image, Film industry, Genre, Description, Price, and Tickets available should not be empty or zero.
    A movie with the same name should not already exist.
    */
    function addMovie(
        string memory _name,
        string memory _image,
        string memory _filmIndustry,
        string memory _genre,
        string memory _description,
        uint _price,
        uint _ticketsAvailable
    ) public onlyOwner {
        require(bytes(_name).length > 0, "Name is required");
        require(bytes(_image).length > 0, "Image is required");
        require(bytes(_filmIndustry).length > 0, "Film industry is required");
        require(bytes(_genre).length > 0, "Genre is required");
        require(bytes(_description).length > 0, "Description is required");
        require(_price > 0, "Price must be greater than zero");
        require(_ticketsAvailable > 0, "Tickets available must be greater than zero");
        // Check that movie with the same name does not already exist
        for (uint i = 0; i < moviesLength; i++) {
            require(keccak256(bytes(movies[i].name)) != keccak256(bytes(_name)), "Movie with same name already exists");
        }

        uint _sold = 0;
        movies[moviesLength] = Movieticket(
            payable(msg.sender),
            _name,
            _image,
            _filmIndustry,
            _genre,
            _description,
            _price,
            _sold,
            _ticketsAvailable,
            true
        );
        moviesLength++;
    }

        /**
        * @dev Retrieves the details of a movie ticket by its index in the `movies` array.
        *
        * @param _index The index of the movie ticket to retrieve.
        *
        * @return admin The Ethereum address of the movie ticket's administrator.
        * @return name The name of the movie associated with the ticket.
        * @return image The IPFS hash of the image associated with the movie.
        * @return filmIndustry The industry to which the movie belongs.
        * @return genre The genre of the movie.
        * @return description A description of the movie.
        * @return price The price of the movie ticket.
        * @return sold The number of tickets sold for the movie.
        * @return ticketsAvailable The number of tickets still available for the movie.
        * @return forSale A boolean indicating whether the movie ticket is currently for sale.
        */
    function getMovieTicket(uint _index) public view returns (
        address payable admin,
        string memory name,
        string memory image,
        string memory filmIndustry,
        string memory genre,
        string memory description,
        uint price,
        uint sold,
        uint ticketsAvailable,
        bool forSale
    ) {
        require(_index < moviesLength, "Invalid index");
        Movieticket memory m = movies[_index];
        return (
            m.admin,
            m.name,
            m.image,
            m.filmIndustry,
            m.genre,
            m.description,
            m.price,
            m.sold,
            m.ticketsAvailable,
            m.forSale
        );
    }

    /**
    * @dev Adds tickets to a movie
    * @param _index The index of the movie in the movies mapping
    * @param _tickets The number of tickets to add
    */
    function addTickets(uint _index, uint _tickets) external isAdmin(_index) {
        require(_tickets > 0, "Number of tickets must be greater than zero");
        require(movies[_index].forSale, "Movie is not available for sale");
    require(movies[_index].ticketsAvailable + _tickets <= movies[_index].ticketsAvailable, "Cannot exceed maximum tickets limit");
        movies[_index].ticketsAvailable += _tickets;
    }

    /**
    @dev Allows the admin to change the sale status of a movie and ensure it has available tickets before putting it on sale.
    @param _index The index of the movie to change the sale status of.
    Requirements:
    The caller must be the admin of the movie.
    The movie must have available tickets to be put on sale.
    Emits a {TicketSaleStatusChange} event.
    */
    function changeForSale(uint _index) external isAdmin(_index) {
        require(movies[_index].forSale == true || movies[_index].ticketsAvailable == 0, "Movie must have available tickets to be put on sale");
        movies[_index].forSale = !movies[_index].forSale;
    }

    /**
    @dev Allows the admin to remove a movie ticket from the list of available movies
    @param _index The index of the movie ticket to be removed
    Requirements:
    - The caller must be the admin of the movie ticket
    - The movie ticket at the specified index must exist
    - The movie ticket must not have any sold tickets
    */
    function removeTicket(uint _index) external isAdmin(_index) {
        require(_index < moviesLength, "Invalid index");
    require(movies[_index].sold == 0, "Cannot remove ticket for a movie with sold tickets");
        movies[_index] = movies[moviesLength - 1];
        delete movies[moviesLength - 1];
        moviesLength--;
    }

    /**
    * @dev Allows the admin to block a certain number of tickets for a movie.
    * @param _index The index of the movie to block tickets for.
    * @param _tickets The number of tickets to block.
    * @notice This function can only be called by the admin of the movie. The movie must have enough tickets available to be blocked.
    */
    function blockTickets(uint _index, uint _tickets) external isAdmin(_index) isTicketAvailable(_index, _tickets) {
        require(_tickets > 0, "Number of tickets must be greater than zero");
        require(movies[_index].ticketsAvailable >= _tickets, "Insufficient tickets available");
        movies[_index].ticketsAvailable -= _tickets;
    }

    /**
    * @dev Allows the user to buy a bulk of tickets for a movie
    * @param _index The index of the movie to buy tickets for
    * @param _tickets The number of tickets to buy
    * Requirements:
    *   - The movie must be for sale
    *   - The required number of tickets must be available
    *   - The buyer must not be the admin
    *   - The transfer of the required funds to the admin account must be successful
    * Effects:
    *   - Reduces the number of tickets available for the movie
    *   - Increases the number of sold tickets for the movie
    *   - Increases the number of tickets purchased by the user for the movie
    *   - Increases the total revenue of the contract
    *   - Emits a TicketPurchase event
    */
    function buyBulkMovieTicket(uint _index, uint _tickets) 
    external payable isTicketForSale(_index) isTicketAvailable(_index, _tickets) {
        require(msg.sender != movies[_index].admin, "Admin cannot buy tickets");
        require(
        IERC20(cUsdTokenAddress).transferFrom(
        msg.sender,
        movies[_index].admin,
        movies[_index].price * _tickets
        ),
        "Transfer failed."
        );    movies[_index].sold += _tickets;
            movies[_index].ticketsAvailable -= _tickets;
            userTickets[msg.sender][_index] += _tickets;

            totalRevenue += movies[_index].price * _tickets;

            emit TicketPurchase(msg.sender, _index, _tickets);
    }

    /**
    * @dev Allows a user to buy a single ticket for a movie.
    * @param _index The index of the movie to purchase a ticket for.
    * @notice The user must not be the admin of the movie and the movie must be available for sale with at least 1 ticket available.
    * @notice The user must not exceed the maximum ticket limit for the movie.
    * @notice The user must transfer the required amount of cUSD tokens to the admin of the movie.
    * @notice The function updates the ticket sales information, user ticket ownership and total revenue, and emits a TicketPurchase event.
    */
    function buyMovieTicket(uint _index) public payable isTicketForSale(_index) isTicketAvailable(_index, 1) {
        require(msg.sender != movies[_index].admin, "Admin cannot buy tickets");
        require(
            IERC20(cUsdTokenAddress).transferFrom(
                msg.sender,
                movies[_index].admin,
                movies[_index].price
            ),
            "Transfer failed."
        );
        require(userTickets[msg.sender][_index] <= movies[_index].ticketsAvailable, "User has exceeded ticket limit");

        movies[_index].sold += 1;
        movies[_index].ticketsAvailable -= 1;
        userTickets[msg.sender][_index] += 1;

        totalRevenue += movies[_index].price;

        emit TicketPurchase(msg.sender, _index, 1);
    }


    /**
    * @dev Allows a user to refund their movie tickets and receive a refund in cUSD tokens.
    * @param _index The index of the movie in the movies array.
    * @param _tickets The number of tickets to refund.
    * Requirements:
    *  - The number of tickets to refund must be greater than zero.
    *  - The user must have purchased at least the number of tickets they are trying to refund.
    *  - The movie must have sold at least the number of tickets being refunded.
    *  - The transfer of cUSD tokens from the movie admin to the user must succeed.
    * Effects:
    *  - The specified number of tickets are refunded and the user's ticket count is decreased.
    *  - The number of tickets sold and the total revenue for the movie are decreased.
    *  - Emits a TicketRefund event.
    */
    function refundTickets(uint _index, uint _tickets) external {
        require(_tickets > 0, "Number of tickets must be greater than zero");
        require(userTickets[msg.sender][_index] >= _tickets, "Insufficient tickets for refund");
         require(movies[_index].sold >= _tickets, "Tickets sold should be greater than refund tickets");


        uint refundAmount = movies[_index].price * _tickets;

        require(
            IERC20(cUsdTokenAddress).transferFrom(
                movies[_index].admin,
                msg.sender,
                refundAmount
            ),
            "Transfer failed."
        );

        movies[_index].sold -= _tickets;
        movies[_index].ticketsAvailable += _tickets;
        userTickets[msg.sender][_index] -= _tickets;

        totalRevenue -= refundAmount;

        emit TicketRefund(msg.sender, _index, _tickets);
    }


    /**
    * @dev Returns the total number of movies/tickets available for sale.
    * @return An unsigned integer representing the length of the `movies` array.
    */
    function getTicketsLength() public view returns (uint) {
        return moviesLength;
    }

    /**
    * @dev Returns the number of tickets bought by the specified user for the movie at the specified index.
    * @param _user The address of the user whose ticket count is to be retrieved.
    * @param _index The index of the movie for which the ticket count is to be retrieved.
    * @return The number of tickets bought by the specified user for the specified movie index.
    * Requirements:
    * - _user address must not be the zero address.
    * - _index must be less than the length of the movies array.
    */
    function getUserTickets(address _user, uint _index) public view returns (uint) {
        require(_user != address(0), "Invalid user address");
        require(_index < moviesLength, "Invalid movie index");
        return userTickets[_user][_index];
    }


    /**
    * @dev Returns the total revenue generated by the cinema contract.
    * @return The total revenue generated in uint.
    */
    function getTotalRevenue() public view returns (uint) {
        return totalRevenue;
    }
}
 
 
```

## How The Contract Works

Let's explain how the contract works!

### Contract Structure and Imports

Let's start by importing the necessary contracts and defining the main structure of our contract.

```solidity
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Movietickets is Ownable {
    // Contract implementation goes here
}

```

In this code snippet, we import the `Ownable` contract from the OpenZeppelin library, which provides basic access control functionality. We also import the `IERC20` contract, which defines the standard interface for ERC20 tokens. The `Movietickets` contract inherits from `Ownable`, making it the contract owner.

## Define MovieTicket Structure and Variables

Next, we define the structure of a movie ticket and declare the required variables.

```solidity
struct Movieticket {
    address payable admin;
    string name;
    string image;
    string filmIndustry;
    string genre;
    string description;
    uint price;
    uint sold;
    uint ticketsAvailable;
    bool forSale;
}

uint internal moviesLength = 0;
address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

mapping (uint => Movieticket) internal movies;
mapping (address => mapping (uint => uint)) internal userTickets;
uint internal totalRevenue = 0;

```

In this code snippet, we define the `Movieticket` struct, which represents the attributes of a movie ticket. The struct contains the following fields:

- `admin`: The address of the ticket administrator who manages the ticket sales.
- `name`: The name of the movie.
- `image`: The image or poster associated with the movie.
- `filmIndustry`: The industry to which the movie belongs (e.g., Hollywood, Bollywood).
- `genre`: The genre of the movie (e.g., action, comedy).
- `description`: A brief description of the movie.
- `price`: The price of each ticket in the specified ERC20 token.
- `sold`: The number of tickets sold for the movie.
- `ticketsAvailable`: The number of tickets currently available for sale.
- `forSale`: A flag indicating whether the movie tickets are available for sale.

We also declare several variables:

- `moviesLength`: Stores the number of movies added to the contract.
- `cUsdTokenAddress`: The address of the ERC20 token contract used for ticket payments.
- `movies`: A mapping that associates each movie index with its corresponding Movieticket struct.
- `userTickets`: A mapping that tracks the number of tickets purchased by each user for each movie.
- `totalRevenue`: Tracks the total revenue generated from ticket sales.


### Define Modifiers

We will define three modifiers to enforce access control and ensure ticket availability

```solidity
modifier isTicketAvailable(uint _index, uint _tickets) {
    require(movies[_index].ticketsAvailable >= _tickets, "Tickets not sufficient");
    _;
}

modifier isTicketForSale(uint _index) {
    require(movies[_index].forSale == true, "Ticket is not for sale");
    _;
}

modifier isAdmin(uint _index) {
    require(msg.sender == movies[_index].admin, "Only admin");
    _;
}

```

-  `isTicketAvailable`: This modifier ensures that the requested number of tickets is available for purchase. It checks if the ticketsAvailable value for the given movie index is greater than or equal to the requested number of tickets.

- `isTicketForSale`: This modifier verifies that the movie tickets are currently available for sale. It checks the forSale flag for the given movie index.

- `isAdmin`: This modifier restricts certain operations to be performed only by the movie administrator. It verifies if the msg.sender (current caller) is the same as the admin address of the movie.

## Add Movie

We will implement a function to add movies to the contract.

```solidity
/**
    @dev Allows owner to add a new movie to the contract.
    @param _name Name of the movie.
    @param _image IPFS hash of the movie poster image.
    @param _filmIndustry Film industry to which the movie belongs.
    @param _genre Genre of the movie.
    @param _description Description of the movie.
    @param _price Price of one movie ticket.
    @param _ticketsAvailable Total number of tickets available for the movie.
    Requirements:
    Only contract owner can call this function.
    Name, Image, Film industry, Genre, Description, Price, and Tickets available should not be empty or zero.
    A movie with the same name should not already exist.
    */
    function addMovie(
        string memory _name,
        string memory _image,
        string memory _filmIndustry,
        string memory _genre,
        string memory _description,
        uint _price,
        uint _ticketsAvailable
    ) public onlyOwner {
        require(bytes(_name).length > 0, "Name is required");
        require(bytes(_image).length > 0, "Image is required");
        require(bytes(_filmIndustry).length > 0, "Film industry is required");
        require(bytes(_genre).length > 0, "Genre is required");
        require(bytes(_description).length > 0, "Description is required");
        require(_price > 0, "Price must be greater than zero");
        require(_ticketsAvailable > 0, "Tickets available must be greater than zero");
        // Check that movie with the same name does not already exist
        for (uint i = 0; i < moviesLength; i++) {
            require(keccak256(bytes(movies[i].name)) != keccak256(bytes(_name)), "Movie with same name already exists");
        }

        uint _sold = 0;
        movies[moviesLength] = Movieticket(
            payable(msg.sender),
            _name,
            _image,
            _filmIndustry,
            _genre,
            _description,
            _price,
            _sold,
            _ticketsAvailable,
            true
        );
        moviesLength++;
    }

```

The `addMovie` function is a Solidity smart contract function that enables the contract owner to add a new movie to the platform. It takes the following input parameters:

- `_name`: A string data type representing the name of the movie.
- `_image`: A string data type representing the image or poster associated with the movie.
- `_filmIndustry`: A string data type representing the industry to which the movie belongs.
- `_genre`: A string data type representing the genre of the movie.
- `_description`: A string data type representing a brief description of the movie.
- `_price`: A uint data type representing the price of each ticket in the specified ERC20 token.
- `_ticketsAvailable`: A uint data type representing the initial number of tickets available for sale.

When called, this function creates a new `Movieticket` struct object with the provided movie details and adds it to the `movies` mapping using the `moviesLength` as the index. Additionally, the `moviesLength` counter is incremented to indicate the total number of movies available on the platform.

### Get Movie Ticket Details

We will implement a function to retrieve the details of a movie ticket.

```solidity
/**
        * @dev Retrieves the details of a movie ticket by its index in the `movies` array.
        *
        * @param _index The index of the movie ticket to retrieve.
        *
        * @return admin The Ethereum address of the movie ticket's administrator.
        * @return name The name of the movie associated with the ticket.
        * @return image The IPFS hash of the image associated with the movie.
        * @return filmIndustry The industry to which the movie belongs.
        * @return genre The genre of the movie.
        * @return description A description of the movie.
        * @return price The price of the movie ticket.
        * @return sold The number of tickets sold for the movie.
        * @return ticketsAvailable The number of tickets still available for the movie.
        * @return forSale A boolean indicating whether the movie ticket is currently for sale.
        */
    function getMovieTicket(uint _index) public view returns (
        address payable admin,
        string memory name,
        string memory image,
        string memory filmIndustry,
        string memory genre,
        string memory description,
        uint price,
        uint sold,
        uint ticketsAvailable,
        bool forSale
    ) {
        require(_index < moviesLength, "Invalid index");
        Movieticket memory m = movies[_index];
        return (
            m.admin,
            m.name,
            m.image,
            m.filmIndustry,
            m.genre,
            m.description,
            m.price,
            m.sold,
            m.ticketsAvailable,
            m.forSale
        );
    }

```

`getMovieTicket` function retrieves and returns the details of a movie ticket using the provided movie index. It returns a tuple containing the following information:

- `admin`: The address of the ticket administrator.
- `name`: The name of the movie.
- `image`: The image or poster associated with the movie.
- `filmIndustry`: The industry to which the movie belongs.
- `genre`: The genre of the movie.
- `description`: A brief description of the movie.
- `price`: The price of each ticket in the specified ERC20 token.
- `sold`: The number of tickets sold for the movie.
- `ticketsAvailable`: The number of tickets currently available for sale.
- `forSale`: A flag indicating whether the movie tickets are available for sale.

The function first validates the input index, ensuring that it is less than the `moviesLength`. It then retrieves the corresponding `Movieticket` struct from the `movies` mapping using the provided index. Finally, the function returns the values of the struct as a tuple.

## Add Tickets

We will implement a function to add more tickets to a movie.

```solidity
/**
    * @dev Adds tickets to a movie
    * @param _index The index of the movie in the movies mapping
    * @param _tickets The number of tickets to add
    */
    function addTickets(uint _index, uint _tickets) external isAdmin(_index) {
        require(_tickets > 0, "Number of tickets must be greater than zero");
        require(movies[_index].forSale, "Movie is not available for sale");
    require(movies[_index].ticketsAvailable + _tickets <= movies[_index].ticketsAvailable, "Cannot exceed maximum tickets limit");
        movies[_index].ticketsAvailable += _tickets;
    }
```

The `addTickets` function enables the movie administrator to add more tickets to a specific movie. It takes the following parameters:

- `_index`: The index of the movie for which tickets are to be added.
- `_tickets`: The number of tickets to add.

The function first checks that the number of tickets to add is greater than zero. It then increases the `ticketsAvailable` value for the specified movie index by the provided number of tickets. This is done by modifying the `movies` mapping at the given index, updating the `ticketsAvailable` field with the new value.

### Change Ticket Sale Status

We will implement a function to change the sale status of a movie ticket.

```solidity
/**
    @dev Allows the admin to change the sale status of a movie and ensure it has available tickets before putting it on sale.
    @param _index The index of the movie to change the sale status of.
    Requirements:
    The caller must be the admin of the movie.
    The movie must have available tickets to be put on sale.
    Emits a {TicketSaleStatusChange} event.
    */
    function changeForSale(uint _index) external isAdmin(_index) {
        require(movies[_index].forSale == true || movies[_index].ticketsAvailable == 0, "Movie must have available tickets to be put on sale");
        movies[_index].forSale = !movies[_index].forSale;
    }
```

The changeForSale function enables the movie administrator to modify the sale status of a specific movie ticket. The function takes a single parameter, which is the index of the movie ticket in question.

The function first retrieves the Movieticket struct from the movies mapping using the provided index. It then toggles the value of the forSale flag associated with the movie ticket. If the flag was previously set to true, indicating that the ticket was available for sale, the function sets it to false, indicating that the ticket is no longer available for sale. Conversely, if the flag was previously set to false, the function sets it to true, indicating that the ticket is now available for sale.

By using the changeForSale function, the movie administrator can easily update the sale status of a movie ticket. This allows them to temporarily remove a ticket from sale if there is an issue with the movie, or to reinstate a ticket if they wish to resume sales.

### Remove Ticket

We will implement a function to remove a movie ticket from the contract.

```solidity
/**
    @dev Allows the admin to remove a movie ticket from the list of available movies
    @param _index The index of the movie ticket to be removed
    Requirements:
    - The caller must be the admin of the movie ticket
    - The movie ticket at the specified index must exist
    - The movie ticket must not have any sold tickets
    */
    function removeTicket(uint _index) external isAdmin(_index) {
        require(_index < moviesLength, "Invalid index");
    require(movies[_index].sold == 0, "Cannot remove ticket for a movie with sold tickets");
        movies[_index] = movies[moviesLength - 1];
        delete movies[moviesLength - 1];
        moviesLength--;
    }
```

The removeTicket function provides the movie administrator with the ability to remove a movie ticket from the smart contract. The function takes a single parameter, which is the index of the movie ticket to be removed.

To remove the movie ticket, the function first replaces the ticket at the specified index with the ticket stored at the end of the movies array. This ensures that there are no gaps in the array and that all indices remain sequential.

After the swap, the function deletes the duplicate entry at the end of the array and decrements the moviesLength variable to reflect the removal of the ticket. This approach prevents the need to shift all the subsequent elements in the array down by one index, which can be computationally expensive.

In summary, the removeTicket function removes a movie ticket from the contract by swapping it with the last element in the movies array and then deleting the duplicate entry at the end of the array.

### Block Tickets

We will implement a function to block a certain number of tickets for a movie.

```solidity
    /**
    * @dev Allows the admin to block a certain number of tickets for a movie.
    * @param _index The index of the movie to block tickets for.
    * @param _tickets The number of tickets to block.
    * @notice This function can only be called by the admin of the movie. The movie must have enough tickets available to be        blocked.
    */
    function blockTickets(uint _index, uint _tickets) external isAdmin(_index) isTicketAvailable(_index, _tickets) {
        require(_tickets > 0, "Number of tickets must be greater than zero");
        require(movies[_index].ticketsAvailable >= _tickets, "Insufficient tickets available");
        movies[_index].ticketsAvailable -= _tickets;
    }
```

The `blockTickets` function allows the movie administrator to block a certain number of tickets for a movie. The function takes two parameters:

- `_index`: The index of the movie for which tickets are to be blocked.
- `_tickets`: The number of tickets to block.

The function first verifies that the requested number of tickets is available for blocking by checking that the sum of tickets already sold and the provided number of tickets is less than or equal to the total number of tickets available. If the requested number of tickets is not available, the function throws an error.

If the requested number of tickets is available, the function decreases the `ticketsAvailable` value for the specified movie index by the provided number of tickets. This ensures that the blocked tickets are not available for purchase by regular users but can be later unblocked and made available for sale by the movie administrator.

### Buy Movie Tickets

We will implement two functions to allow users to purchase movie tickets.

```solidity
/**
    * @dev Allows the user to buy a bulk of tickets for a movie
    * @param _index The index of the movie to buy tickets for
    * @param _tickets The number of tickets to buy
    * Requirements:
    *   - The movie must be for sale
    *   - The required number of tickets must be available
    *   - The buyer must not be the admin
    *   - The transfer of the required funds to the admin account must be successful
    * Effects:
    *   - Reduces the number of tickets available for the movie
    *   - Increases the number of sold tickets for the movie
    *   - Increases the number of tickets purchased by the user for the movie
    *   - Increases the total revenue of the contract
    *   - Emits a TicketPurchase event
    */
    function buyBulkMovieTicket(uint _index, uint _tickets) 
    external payable isTicketForSale(_index) isTicketAvailable(_index, _tickets) {
        require(msg.sender != movies[_index].admin, "Admin cannot buy tickets");
        require(
        IERC20(cUsdTokenAddress).transferFrom(
        msg.sender,
        movies[_index].admin,
        movies[_index].price * _tickets
        ),
        "Transfer failed."
        );    movies[_index].sold += _tickets;
            movies[_index].ticketsAvailable -= _tickets;
            userTickets[msg.sender][_index] += _tickets;

            totalRevenue += movies[_index].price * _tickets;

            emit TicketPurchase(msg.sender, _index, _tickets);
    }
```
The `buyBulkMovieTicket` function allows users to purchase multiple movie tickets at once. It takes two parameters:

- `_index`: The index of the movie for which tickets are to be purchased.
- `_tickets`: The number of tickets to purchase.

Before processing the transaction, the function performs several checks. It verifies that the movie tickets are available for sale and that the requested number of tickets is available. It also ensures that the caller is not the movie administrator to prevent the purchase of tickets by the movie's internal staff.

The function transfers the required amount of ERC20 tokens from the caller to the movie administrator using the `transferFrom` function of the ERC20 token contract. It then updates the ticket sales and availability data by increasing the `sold` count for the specified movie and decreasing the `ticketsAvailable` count accordingly. It also increments the user's ticket count for the specified movie and increases the total revenue of the contract.

Finally, the function emits a `TicketPurchase` event to notify listeners about the ticket purchase, including the movie index, the number of tickets purchased, the user address, and the total price paid for the tickets.

```solidity
**
    * @dev Allows a user to buy a single ticket for a movie.
    * @param _index The index of the movie to purchase a ticket for.
    * @notice The user must not be the admin of the movie and the movie must be available for sale with at least 1 ticket available.
    * @notice The user must not exceed the maximum ticket limit for the movie.
    * @notice The user must transfer the required amount of cUSD tokens to the admin of the movie.
    * @notice The function updates the ticket sales information, user ticket ownership and total revenue, and emits a TicketPurchase event.
    */
    function buyMovieTicket(uint _index) public payable isTicketForSale(_index) isTicketAvailable(_index, 1) {
        require(msg.sender != movies[_index].admin, "Admin cannot buy tickets");
        require(
            IERC20(cUsdTokenAddress).transferFrom(
                msg.sender,
                movies[_index].admin,
                movies[_index].price
            ),
            "Transfer failed."
        );
        require(userTickets[msg.sender][_index] <= movies[_index].ticketsAvailable, "User has exceeded ticket limit");

        movies[_index].sold += 1;
        movies[_index].ticketsAvailable -= 1;
        userTickets[msg.sender][_index] += 1;

        totalRevenue += movies[_index].price;

        emit TicketPurchase(msg.sender, _index, 1);
    }

```

The buyMovieTicket function allows a user to purchase a single movie ticket. It takes the movie index as a parameter and verifies that the movie ticket is available for sale and that at least one ticket is available. It also ensures that the caller is not the movie administrator.

If all conditions are met, the function transfers the required amount of ERC20 tokens from the caller to the movie administrator using the transferFrom function. It updates the ticket sales and availability data, increments the user's ticket count for the specified movie, increases the total revenue of the contract, and emits a TicketPurchase event to notify listeners about the ticket purchase.

### Refund Tickets

We will implement a function to allow users to refund their purchased tickets.

```solidity
/**
    * @dev Allows a user to refund their movie tickets and receive a refund in cUSD tokens.
    * @param _index The index of the movie in the movies array.
    * @param _tickets The number of tickets to refund.
    * Requirements:
    *  - The number of tickets to refund must be greater than zero.
    *  - The user must have purchased at least the number of tickets they are trying to refund.
    *  - The movie must have sold at least the number of tickets being refunded.
    *  - The transfer of cUSD tokens from the movie admin to the user must succeed.
    * Effects:
    *  - The specified number of tickets are refunded and the user's ticket count is decreased.
    *  - The number of tickets sold and the total revenue for the movie are decreased.
    *  - Emits a TicketRefund event.
    */
    function refundTickets(uint _index, uint _tickets) external {
        require(_tickets > 0, "Number of tickets must be greater than zero");
        require(userTickets[msg.sender][_index] >= _tickets, "Insufficient tickets for refund");
         require(movies[_index].sold >= _tickets, "Tickets sold should be greater than refund tickets");


        uint refundAmount = movies[_index].price * _tickets;

        require(
            IERC20(cUsdTokenAddress).transferFrom(
                movies[_index].admin,
                msg.sender,
                refundAmount
            ),
            "Transfer failed."
        );

        movies[_index].sold -= _tickets;
        movies[_index].ticketsAvailable += _tickets;
        userTickets[msg.sender][_index] -= _tickets;

        totalRevenue -= refundAmount;

        emit TicketRefund(msg.sender, _index, _tickets);
    }

```

The refundTickets function allows users to refund their purchased tickets. It takes the following parameters:

_index: The index of the movie for which tickets are to be refunded.
_tickets: The number of tickets to be refunded.
The function verifies that the requested number of tickets to be refunded is greater than zero and that the user has enough tickets to refund for the specified movie.

It calculates the refund amount by multiplying the ticket price with the number of tickets to be refunded.

Using the transferFrom function of the ERC20 token contract, it transfers the refund amount from the movie administrator back to the user.

Then, it updates the ticket sales and availability data, decrements the user's ticket count, reduces the total revenue of the contract, and emits a TicketRefund event to notify listeners about the ticket refund.

### Additional Helper Functions

```solidity
    /**
    * @dev Returns the total number of movies/tickets available for sale.
    * @return An unsigned integer representing the length of the `movies` array.
    */
    function getTicketsLength() public view returns (uint) {
        return moviesLength;
    }
```

The `getTicketsLength` function returns the total number of movies in the contract.

```solidity
/**
    * @dev Returns the number of tickets bought by the specified user for the movie at the specified index.
    * @param _user The address of the user whose ticket count is to be retrieved.
    * @param _index The index of the movie for which the ticket count is to be retrieved.
    * @return The number of tickets bought by the specified user for the specified movie index.
    * Requirements:
    * - _user address must not be the zero address.
    * - _index must be less than the length of the movies array.
    */
    function getUserTickets(address _user, uint _index) public view returns (uint) {
        require(_user != address(0), "Invalid user address");
        require(_index < moviesLength, "Invalid movie index");
        return userTickets[_user][_index];
    }

```

The `getUserTickets` function returns the number of tickets owned by a specific user for a given movie index.

```solidity
function getTotalRevenue() public view returns (uint) {
/**
    * @dev Returns the total revenue generated by the cinema contract.
    * @return The total revenue generated in uint.
    */
    function getTotalRevenue() public view returns (uint) {
        return totalRevenue;
    }

```

The `getTotalRevenue` function returns the total revenue generated by ticket sales in the contract.

## Deployment

Here is how to deploy your smart contract on the celo blockchain

Install the Celo Extension Wallet: You can download and install the wallet from the Chrome Web Store using this link: https://chrome.google.com/webstore/detail/celoextensionwallet/kkilomkmpmkbdnfelcpgckmpcaemjcdh?hl=en.

Fund your Celo wallet: Once you have created your wallet, you will need to fund it with Celo tokens. You can use the Celo Alfajores faucet to get some test tokens by visiting this link: https://celo.org/developers/faucet.

Install the Celo plugin: Click on the plugin logo at the bottom left corner and search for the Celo plugin. Install the plugin and click on the Celo logo which will show in the side tab after the plugin is installed.

Connect your Celo wallet: Click on the Celo logo in the side tab and select the "Connect Wallet" option. You will need to authorize the plugin to access your wallet.

Select the contract you want to deploy: Once your wallet is connected, select the contract you want to deploy. This can be a contract you have written yourself or an existing contract from a repository like OpenZeppelin.

Deploy your contract: Click on the "Deploy" button to deploy your contract. You will be prompted to confirm the transaction and pay a small fee in Celo tokens for the deployment.

Wait for confirmation: Once you have confirmed the transaction, you will need to wait for it to be processed and confirmed on the Celo blockchain. This can take a few minutes to several hours depending on network congestion and other factors.

Interact with your deployed contract: Once your contract is deployed, you can interact with it using the Celo plugin. You can call its functions, view its state, and perform other actions as needed.

## Conclusion

Well done, fellow developers! You have just accomplished a great feat by implementing a Movie Tickets smart contract using Solidity. With this contract, movie administrators can easily add movies, manage ticket availability, sell tickets to users, refund tickets, and track revenue with seamless efficiency. This is a great addition to your skill set as a blockchain developer and can be used as a reference for building similar contracts in the future. Keep up the good work!

## Next Steps

Here are some relevant links to further enhance your knowledge and skills on building a Movie Ticket Smart Contract on the Celo Blockchain:

- [Official Celo Docs](https://docs.celo.org/): A comprehensive documentation of Celo Blockchain that covers everything from getting started to advanced topics.
- [Official Solidity Docs](https://docs.soliditylang.org/en/v0.8.17/): The official Solidity documentation that provides detailed information on the Solidity programming language used to build smart contracts on Ethereum and other compatible blockchains.

These resources will not only help you with Celo and Solidity, but also enable you to create more robust and complex smart contracts. Keep learning and happy coding!
