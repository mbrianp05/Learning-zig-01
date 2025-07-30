const std = @import("std");

const Node = struct {
    value: i32,
    left: ?*Node = null,
    right: ?*Node = null,
    arena: std.heap.ArenaAllocator,

    pub fn init(allocator: std.mem.Allocator, value: i32) !*Node {
        var arena = std.heap.ArenaAllocator.init(allocator);
        const node = try arena.allocator().create(Node);

        node.* = .{ .value = value, .arena = arena };

        return node;
    }

    pub fn deinit(self: *Node) void {
        self.arena.deinit();
    }

    pub fn height(self: *Node) u32 {
        var rightHeight: u32 = 0;
        var leftHeight: u32 = 0;

        if (self.right) |right| {
            rightHeight = right.height();
        }

        if (self.left) |left| {
            leftHeight = left.height();
        }

        // Tree root does not count
        // So we do not add level when reaching terminal nodes
        if (self.left == null and self.right == null) return 0;
        const max = if (rightHeight > leftHeight) rightHeight else leftHeight;

        return max + 1;
    }

    pub fn search(self: *Node, value: i32) ?*Node {
        if (self.value == value) return self;

        if (self.value > value) {
            if (self.left) |left| {
                return left.search(value);
            }

            return null;
        }

        if (self.right) |right| {
            return right.search(value);
        }

        return null;
    }

    pub fn insert(self: *Node, value: i32) !void {
        if (self.value == value) {
            return;
        }

        if (self.value > value) {
            if (self.left) |left| {
                try left.insert(value);
                return;
            }

            self.left = try Node.init(self.arena.allocator(), value);
            return;
        }

        if (self.right) |right| {
            try right.insert(value);
            return;
        }

        self.right = try Node.init(self.arena.allocator(), value);
    }

    pub fn inorder(self: *Node, allocator: std.mem.Allocator) !std.ArrayList(*Node) {
        var list = std.ArrayList(*Node).init(allocator);
        try self.inorderRec(&list);

        return list;
    }

    fn inorderRec(self: *Node, list: *std.ArrayList(*Node)) !void {
        if (self.left) |left| {
            try left.inorderRec(list);
        }

        try list.append(self);

        if (self.right) |right| {
            try right.inorderRec(list);
        }
    }

    pub fn nodesAtDepth(self: *Node, allocator: std.mem.Allocator, depth: u32) !std.ArrayList(*Node) {
        if (depth > self.height()) {
            return error.DepthGreaterThanTreeHeight;
        }

        var nodes = std.ArrayList(*Node).init(allocator);
        try self.nodesAtDepthRec(&nodes, depth);

        return nodes;
    }

    fn nodesAtDepthRec(self: *Node, nodes: *std.ArrayList(*Node), depth: u32) !void {
        if (depth == 0) {
            try nodes.append(self);

            return;
        }

        if (self.left) |left| {
            try left.nodesAtDepthRec(nodes, depth - 1);
        }

        if (self.right) |right| {
            try right.nodesAtDepthRec(nodes, depth - 1);
        }
    }

    fn padding(spaces: u32, char: u8) void {
        for (0..spaces) |_| {
            std.debug.print("{c}", .{char});
        }
    }

    pub fn printTree(self: *Node) !void {
        try self.printTreeRec(0);
    }

    fn printTreeRec(self: *Node, depth: u32) !void {
        const h = self.height();

        if (depth > h) return;
        padding((h - depth) * 8, ' ');

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        const allocator = gpa.allocator();

        const nodes = try self.nodesAtDepth(allocator, depth);
        defer nodes.deinit();

        for (nodes.items, 0..) |node, index| {
            std.debug.print("{d}", .{node.value});
            const padSize = if (index % 2 != 0) 3 else h * 8;

            padding(padSize, ' ');
        }

        std.debug.print("\n", .{});

        try self.printTreeRec(depth + 1);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const tree = try Node.init(allocator, 10);
    defer tree.deinit();

    try tree.insert(20);
    try tree.insert(7);
    try tree.insert(15);
    try tree.insert(5);
    try tree.insert(8);
    try tree.insert(22);

    const list = try tree.inorder(allocator);
    defer list.deinit();

    for (list.items) |node| {
        std.debug.print("{d} ", .{node.value});
    }

    std.debug.print("\n", .{});

    const search = tree.search(12);

    if (search == null) {
        std.debug.print("search: null\n", .{});
    } else {
        std.debug.print("search: {d}\n", .{search.?.value});
    }

    const depth = 2;

    const nodes = try tree.nodesAtDepth(allocator, depth);
    defer nodes.deinit();

    std.debug.print("Nodes at depth {d}: ", .{depth});

    for (nodes.items) |item| {
        std.debug.print("{d} ", .{item.value});
    }

    std.debug.print("\n", .{});

    try tree.printTree();
}
