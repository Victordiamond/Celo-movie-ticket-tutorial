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
