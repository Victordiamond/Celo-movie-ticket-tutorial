---
title: Building a Movie Ticketing Smart Contract on the Celo Blockchain
description: This tutorial will teach you how to create a movie ticket on celo blockchain for cinemas booking
authors:
  - name: Ubah Victor
---

## Introduction

This tutorial guides you through the process of building a movie ticketing smart contract using Solidity on the Celo blockchain. The smart contract allows users to purchase movie tickets, manage ticket availability, and track revenue.

We will also go through the concept of smart contracts and their benefits. Explain the purpose of the movie ticketing smart contract and how it leverages blockchain technology for secure and transparent ticket transactions.

By following this tutorial, users will gain practical experience in developing a movie ticketing smart contract and understand the underlying concepts of blockchain-based systems.

## Prerequisites

Before getting started, ensure you have the following:

- Basic understanding of Solidity and smart contracts.

- A development environment like remix

## SmartContract

Let's begin writing our smart contract in Remix IDE

This is the complete code.

```solidity
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Movietickets is Ownable {
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

    event TicketPurchase(address indexed buyer, uint indexed movieIndex, uint ticketCount);
    event TicketRefund(address indexed buyer, uint indexed movieIndex, uint ticketCount);

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

    function addMovie(
        string memory _name,
        string memory _image,
        string memory _filmIndustry,
        string memory _genre,
        string memory _description,
        uint _price,
        uint _ticketsAvailable
    ) public onlyOwner {
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

    function getMovieTicket(uint _index) public view returns (
        address payable,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        uint,
        uint,
        uint,
        bool
    ) {
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

    function addTickets(uint _index, uint _tickets) external isAdmin(_index) {
        require(_tickets > 0, "Number of tickets must be greater than zero");
        movies[_index].ticketsAvailable += _tickets;
    }

    function changeForSale(uint _index) external isAdmin(_index) {
        movies[_index].forSale = !movies[_index].forSale;
    }

    function removeTicket(uint _index) external isAdmin(_index) {
        movies[_index] = movies[moviesLength - 1];
        delete movies[moviesLength - 1];
        moviesLength--;
    }

    function blockTickets(uint _index, uint _tickets) external isAdmin(_index) isTicketAvailable(_index, _tickets) {
        movies[_index].ticketsAvailable -= _tickets;
    }

    function buyBulkMovieTicket(uint _index, uint _tickets
) external payable isTicketForSale(_index) isTicketAvailable(_index, _tickets) {
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

    movies[_index].sold += 1;
    movies[_index].ticketsAvailable -= 1;
    userTickets[msg.sender][_index] += 1;

    totalRevenue += movies[_index].price;

    emit TicketPurchase(msg.sender, _index, 1);
}

function refundTickets(uint _index, uint _tickets) external {
    require(_tickets > 0, "Number of tickets must be greater than zero");
    require(userTickets[msg.sender][_index] >= _tickets, "Insufficient tickets for refund");

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

function getTicketsLength() public view returns (uint) {
    return moviesLength;
}

function getUserTickets(address _user, uint _index) public view returns (uint) {
    return userTickets[_user][_index];
}

function getTotalRevenue() public view returns (uint) {
    return totalRevenue;
}
}
 
```

## How The Contract Works

Let's explain how the contract works!

**Contract Structure and Imports**

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

**Define MovieTicket Structure and Variables**

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


**Define Modifiers**

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

**Add Movie**

We will implement a function to add movies to the contract.

```solidity
function addMovie(
    string memory _name,
    string memory _image,
    string memory _filmIndustry,
    string memory _genre,
    string memory _description,
    uint _price,
    uint _ticketsAvailable
) public onlyOwner {
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

The `addMovie` function allows the contract owner to add a new movie. It takes the following parameters:

- `_name`: The name of the movie.
- `_image`: The image or poster associated with the movie.
- `_filmIndustry`: The industry to which the movie belongs.
- `_genre`: The genre of the movie.
- `_description`: A brief description of the movie.
- `_price`: The price of each ticket in the specified ERC20 token.
- `_ticketsAvailable`: The initial number of tickets available for sale.

The function creates a new `Movieticket` struct with the provided details and adds it to the `movies` mapping using the `moviesLength` as the index. The `moviesLength` is then incremented.

**Get Movie Ticket Details**

We will implement a function to retrieve the details of a movie ticket.

```solidity
function getMovieTicket(uint _index) public view returns (
    address payable,
    string memory,
    string memory,
    string memory,
    string memory,
    string memory,
    uint,
    uint,
    uint,
    bool
) {
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

The `getMovieTicket` function takes a movie index as input and returns the details of the corresponding movie ticket. It returns a tuple containing the following information:

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

The function retrieves the corresponding `Movieticket` struct from the `movies` mapping using the provided index and returns the values as a tuple.

**Add Tickets**

We will implement a function to add more tickets to a movie.

```solidity
function addTickets(uint _index, uint _tickets) external isAdmin(_index) {
    require(_tickets > 0, "Number of tickets must be greater than zero");
    movies[_index].ticketsAvailable += _tickets;
}

```

The `addTickets` function allows the movie administrator to add more tickets to a movie. It takes the following parameters:

- `_index`: The index of the movie for which tickets are to be added.
- `_tickets`: The number of tickets to add.

The function verifies that the number of tickets to add is greater than zero. It then increases the `ticketsAvailable` value for the specified movie index by the provided number of tickets.

**Change Ticket Sale Status**

We will implement a function to change the sale status of a movie ticket.

```solidity
function changeForSale(uint _index) external isAdmin(_index) {
    movies[_index].forSale = !movies[_index].forSale;
}

```

The `changeForSale` function allows the movie administrator to toggle the sale status of a movie ticket. It takes the movie index as a parameter.

The function flips the value of the `forSale` flag for the specified movie index. If the ticket was previously for sale, it will be marked as not for sale, and vice versa.

**Remove Ticket**

We will implement a function to remove a movie ticket from the contract.

```solidity
function removeTicket(uint _index) external isAdmin(_index) {
    movies[_index] = movies[moviesLength - 1];
    delete movies[moviesLength - 1];
    moviesLength--;
}

```

The `removeTicket` function allows the movie administrator to remove a movie ticket from the contract. It takes the movie index as a parameter.

The function replaces the ticket at the specified index with the ticket stored at the end of the `movies` array. It then deletes the duplicate entry at the end of the array and decrements the `moviesLength` variable.

**Block Tickets**

We will implement a function to block a certain number of tickets for a movie.

```solidity
function blockTickets(uint _index, uint _tickets) external isAdmin(_index) isTicketAvailable(_index, _tickets) {
    movies[_index].ticketsAvailable -= _tickets;
}

```

The `blockTickets` function allows the movie administrator to block a certain number of tickets for a movie. It takes the following parameters:

- `_index`: The index of the movie for which tickets are to be blocked.
- `_tickets`: The number of tickets to block.

The function verifies that the requested number of tickets is available for blocking. It then decreases the `ticketsAvailable` value for the specified movie index by the provided number of tickets.

**Buy Movie Tickets**

We will implement two functions to allow users to purchase movie tickets.

```solidity
function buyBulkMovieTicket(uint _index, uint _tickets) external payable isTicketForSale(_index) isTicketAvailable(_index, _tickets) {
    require(msg.sender != movies[_index].admin, "Admin cannot buy tickets");
    require(
        IERC20(cUsdTokenAddress).transferFrom(
msg.sender,
movies[_index].admin,
movies[_index].price * _tickets
),
"Transfer failed."
);
movies[_index].sold += _tickets;
movies[_index].ticketsAvailable -= _tickets;
userTickets[msg.sender][_index] += _tickets;

totalRevenue += movies[_index].price * _tickets;

emit TicketPurchase(msg.sender, _index, _tickets);
}
The `buyBulkMovieTicket` function allows users to purchase multiple movie tickets at once. It takes the following parameters:
- `_index`: The index of the movie for which tickets are to be purchased.
- `_tickets`: The number of tickets to purchase.

The function verifies that the movie tickets are available for sale and that the requested number of tickets is available. It also ensures that the caller is not the movie administrator.

The function transfers the required amount of ERC20 tokens from the caller to the movie administrator using the `transferFrom` function of the ERC20 token contract. It then updates the ticket sales and availability data, increments the user's ticket count for the specified movie, and increases the total revenue of the contract.

Finally, the function emits a `TicketPurchase` event to notify listeners about the ticket purchase.

```solidity
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

    movies[_index].sold += 1;
    movies[_index].ticketsAvailable -= 1;
    userTickets[msg.sender][_index] += 1;

    totalRevenue += movies[_index].price;

    emit TicketPurchase(msg.sender, _index, 1);
}

```

The `buyMovieTicket` function allows users to purchase a single movie ticket. It takes the movie index as a parameter.

The function verifies that the movie ticket is available for sale and that at least one ticket is available. It also ensures that the caller is not the movie administrator.

Similar to the `buyBulkMovieTicket` function, it transfers the required amount of ERC20 tokens from the caller to the movie administrator using the `transferFrom` function. It updates the ticket sales and availability data, increments the user's ticket count, increases the total revenue, and emits a `TicketPurchase` event.

**Refund Tickets**

We will implement a function to allow users to refund their purchased tickets.

```solidity
function refundTickets(uint _index, uint _tickets) external {
    require(_tickets > 0, "Number of tickets must be greater than zero");
    require(userTickets[msg.sender][_index] >= _tickets, "Insufficient tickets for refund");

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

The `refundTickets` function allows users to refund their purchased tickets. It takes the following parameters:

- `_index`: The index of the movie for which tickets are to be refunded.
- `_tickets`: The number of tickets to be refunded.

The function verifies that the requested number of tickets to be refunded is greater than zero and that the user has enough tickets to refund for the specified movie.

It calculates the refund amount by multiplying the ticket price with the number of tickets to be refunded.

Using the `transferFrom` function of the ERC20 token contract, it transfers the refund amount from the movie administrator back to the user.

Then, it updates the ticket sales and availability data, decrements the user's ticket count, reduces the total revenue of the contract, and emits a `TicketRefund` event to notify listeners about the ticket refund.

**Additional Helper Functions**

```solidity
function getTicketsLength() public view returns (uint) {
    return moviesLength;
}

```

The `getTicketsLength` function returns the total number of movies in the contract.

```solidity
function getUserTickets(address _user, uint _index) public view returns (uint) {
    return userTickets[_user][_index];
}

```

The `getUserTickets` function returns the number of tickets owned by a specific user for a given movie index.

```solidity
function getTotalRevenue() public view returns (uint) {
    return totalRevenue;
}

```

The `getTotalRevenue` function returns the total revenue generated by ticket sales in the contract.

## Deployment

To deploy our smart contract successfully, we need the celo extention wallet which can be downloaded from [here](https://chrome.google.com/webstore/detail/celoextensionwallet/kkilomkmpmkbdnfelcpgckmpcaemjcdh?hl=en)

Next, we need to fund our newly created wallet which can done using the celo alfojares faucet [Here](https://celo.org/developers/faucet)

Now, click on the plugin logo at the bottom left corner and search for celo plugin.

Install the plugin and click on the celo logo which will show in the side tab after the plugin is installed.

Next connect your celo wallet, select the contract you want to deploy and finally click on deploy to deploy your contract.

## Conclusion

Congratulations! You have successfully implemented a Movie Tickets smart contract using Solidity. The contract allows movie administrators to add movies, manage ticket availability, sell tickets to users, refund tickets, and track revenue

## Next Steps

With us coming to the end of this tutorial, I hope you've learned on how to build a Movie Ticket Smart Contract on the Celo Blockchain. Here are some relevant links that would aid your learning further.

- [Official Celo Docs](https://docs.celo.org/)
- [Official Solidity Docs](https://docs.soliditylang.org/en/v0.8.17/)